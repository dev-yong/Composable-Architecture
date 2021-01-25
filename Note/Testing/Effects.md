# Testable State Management: Effects

### [Testing effects](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t44)

- Redcuer 는 pure function으로 되어있기에 test하기가 매우 용이하였다.
  1.  현재 상태를 설명하는 변경 가능한 state를 구성한다.
  2. 해당 state를 reducer에 적용한다.
  3. reducer에 의하여 변경된 state를 예상하는 결과값과 같은지 확인한다.
- Effect는 테스트하기가 용이하지 않다.
  - Reducer를 호출할 때, redcuer가 effect가 없거나 몇 개의 effect를 생성하는 지에 대하여 확인할 수 있지만, `Effect` 타입은 함수를 감싸는 단순한 wrapper이기 때문에 어떠한 effect가 생성되었는 가에 대한 확인을 할 수는 없다.
  - 이러한 문제를 해결하기 위하여, Reducer가 해당 응답으로 작업을 수행하고 있는지 확인할 수 있도록 Effect가 생성 할 것으로 예상한 작업을 수동으로 실행하였다.
    - 하지만 이러한 작업은 실수로 인하여 빠지는 부분이 생길 수도 있으며,  Effectf를 테스트하지 않고 있다는 것을 의미하기도 한다.
- Effect를 실행하여 테스트를 할 수는 있지만, Effect 그 자체는 테스트할 수 없다.
  - 예를 들어, save effect를 실행하는 경우 디스크의 어딘가에 JSON 데이터가 올바르게 작성되어있는지 확인하기 위하여 해당 파일의 위치를 알아야한다. 혹은 save effect와 load effect를 동시에 테스트하여야 한다.
    - 파일 시스템과 상호 작용해야한다는 단점이 있다.
- Effect의 테스트 복잡도는 Effect의 복잡도에 비례한다.
  - e.g. asynchronous effect

### [Recap: the environment](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t156)

- **Environment**를 통하여 어플리케이션의 **모든 종속성을 변경가능한 필드를 갖는 단일 데이터 유형으로 묶을 수 있도록 한다**.
- Environment를 통하여 **실제 구현체와 mock 구현체에 대한 교체가 매우 쉬워진다**.

- Environment에 종속성이 추가되는 방법을 기억하기 위해  모듈이 현재 날짜에 액세스해야한다고 가정해보자.
  - 날짜를 만들때 마다 시간이 변경되기 때문에 이것은 확실히 side effect이다.
  - 그러나, 코드 상에서 직접 date initializer를 호출하는 대신 Environment에 추가할 수 있다.
  - 또한, 이러한 종속성의 디폴트, `live` 구현을 통해 환경을 확장할 수 있다.
  - 모듈에 global environment가 있으므로, 날짜에 액세스하고 싶을 때마다 그저 `current` Environment에 접근하면 된다.
    - 이는 즉, 날짜 값을 얻을 때 제어되지 않은 날짜 initializer에 접근하는 것을 막고, 현재 **Environment를 통과하도록 강제** 한다는 것이다.
  - 또한, date는 변경 가능한 속성이기 때문에 훨씬 더 제어 가능한 방식으로 구현을 바꿀 수 있다. e.g. `mock`

```swift
struct Environment {
    
    var date: () -> Date
    
}

extension Environment {
    
    static let live = Environment(
        date: Date.init
    )
    
    static let mock = Environment(
        date: { Date(timeIntervalSince1970: 1234567890) }
    )
    
}

var current = Environment.live
```

- Environment
  - 종속성을 설명하는 변경가능한 필드가 있는 구조체를 만든다.
  - 종속성의 라이브 버전을 가리키는 live를 만든다.
  - mock 버전을 사용하고 다른 mock 시나리오로 교체할 수 있다.

### [Controlling the favorite primes save effect](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t464)

- Envionrimet에 놓을 수 있는 종속성에서 이러한 effect를 포착하고자 한다.
- Save 및 Load effect에 대한 필드를 이 구조체에 직접 추가 할 수 있지만 서로 연관이 있으므로 `FileClient`를 추가한다.

#### Load

- `load` 는 소수를 나타내는 정수 배열을 생성하는 것으로 ` var load: () -> [Int]?` 와 같이 행하고자 할 수 있다. 하지만 몇 가지의 문제가 존재한다.
  - Effect가 발생할 것이라는 표시를 제공하지 않는다.
  - `favorite-primes.json` 파일에서 문자 그대로 정수배열을 로드하는 사례에 대해서만 구체적이다.
    - 일반화하여 파일명을 전달하고 데이터를 다시 가져오도록 한 다음 json 	decoding을 직접 수행할 수 있어야 한다.
- 파일명을 인자로 받고, optional data를 반환하여 optional 정수 배열을 일반화 한다. `var load: (_ fileName: String) -> Effect<Data?>`

#### Save

- Save effect는 fire-and-forget effect이다.
  - 데이터를 디스크에 저장하는 작업만 수행하면 되고 데이터를 다시 시스템으로 보낼 필요가 없다.
  - `var save: (_ fileName: String, _ data: Data) -> Effect<FavoritePrimesAction>`
- 하지만 위의 코드는 불필요하게 FileClient를 favorite primes 모듈에 직접 연결하고 있다. 그로 인하여 FileClient를 자체 모듈로 추출할 수 없다.
- FileClient를 일반화하여 FileClient에서 Effect의 유형을 분리할 수 있다.

```swift
struct FileClient<Action> {
  // …
  var save: (String, Data) -> Effect<A>
}
```

- `save` effect가 시스템에 피드백되는 작업을 생성하는 것 조차 원하지 않을 수 있다. `var save: (String, Data) -> Effect<Void>` 

- 하지만, 이것조차도 `Void` 라는 value를 시스템에 보내게 된다.
  - 어떠한 **일을 수행할 수는 있지만, 절대 value를 만들 수 없는 effect**가 필요로 하다.
  - **작업을 저장소로 다시 보낼 수 있는 기능 자체가 없어야한다.**
  - 이 때, `Never` 를 이용한다. `var save: (String, Data) -> Effect<Never>` 

- `Never` 는 "uninhabited(무인의, 사람이 살지 않는)" 타입이라고 불리운다.
  - enum 형식이며, 어떠한 case 도 가지고 있지 않다.
  - `Never` type의 값을 생성하는 것은 불가능하다.
  - 그렇기 때문에, effect publihs가 `Never` 타입의 방출을 생성하는 것도 불가능하다.
  - `Effect <Never> ` 타입을 겪은 적이 있다면 구현을 보지 않고도 값을 생성 할 수 없다는 것을 알 수 있으므로 fire-and-forget effect 여야한다.

- `absurd` 를 이용하여  `Never`를` FavoritePrimeAction`으로 변환하도록 한다.

```swift
func absurd<A>(_ never: Never) -> A {}
```

- absurd를 리팩토링하여 `fireAndForget` operator를 추가한다.

```swift
extension Publisher where Output == Never, Failure == Never {
    
  public func fireAndForget<A>() -> Effect<A> {
    return self.map(absurd).eraseToEffect()
  }
    
}
private func absurd<A>(_ never: Never) -> A {}
```

### [Controlling the favorite primes load effect](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t1026)

- `load` effect는 `Data?` 를 반환하기에 decode가 필요로 하다.
- 하지만, `decode` 는 `Data` publisher에서만 작동하므로optional에 대한 처리가 필요로 하다.
- `decode` 는 실패할 수 있는 publisher를 제공하고 있지만, Effect publisher를 모든 실패를 명시적으로 처리해야하기 때문에 실패를 허용하고 있지 않다(Never).
- `catch`  메서드를 사용하여이 문제를 해결할 수 있다.
  - Pulisher가 생성하는 오류를 가로채서 완전히 새로운 publisher에 mapping할 수 있다. 
  - 오류를 완전히 무시하기를 원하므로 즉시 완료되는 publisher에 mapping할 수 있다.

- FavoritePrimesEnvironment에 대한 live, mock 을 추가하여 적용하도록 한다.

### [Testing the favorite primes save effect](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t1459)

- 기존의 `testSaveButtonTapped()` 는 매우 간단한 테스트를 수행하고 있다.
  - state를 변경하지 않고, effect를 방출하기만 한다.
  - 이 effect를 테스트하기 위하여 effect를 실행할 수 있다.
- Save effect의 Environment는 live를 사용하고 있다.
  - 즉, 이 효과는 디스크에서 파일을 찾고 저장된 내용을 확인해야한다.
  - 하지만, 디시크에 대한 읽기/쓰기 권한이 없을 수도 있어 매우 취약한 작업이다.
  - 따라서, **mock environment를 사용하여 실제 디스크 스토리지를 처리하는 모호함을 제거**할 수 있다.
- 테스트의 중점은 "save effect가 호출되었는 가"이다.
  - mock effect서 이를 포착하기 위해 save effect가 실행되었는지 여부를 나타내는 가변 bool을 유지하고 effect 내부에서 뒤집는다.

```swift
var didSave = false
Current.fileClient.save = { _, data in
    .fireAndForget {
        didSave = true
    }
}
```

- Save effect가 제대로 `didSave` 변수를 변경시켰는지 확인하기 위하여 effect를 수행하고 해당 값을 확인한다.

```swift
_ = effects[0].sink { _ in }

XCTAssert(didSave)
```

- 또한, 이 effect는 fire-and-forget이기 때문에 effect에 대한 콜백이 절대 수행되지 않을 것임을 확인할 수 있다. `_ = effects[0].sink { _ in XCTFail() }`

- 설정이 거의없고 매우 직접적인 방식으로 사용자가 저장 버튼을 누를 때 상태를 변경하지 않고 save에 대한 종속성을 호출하고 다른 어떤 것도 방출하지 않는 단일 side effect이 실행된다는 것을 확인할 수 있다.
  - 이러한 이점을 얻는 이유 중 하나는 **종속성 설정 방식 때문**이다.
  - 이 스타일의 테스트는 종속성이 가능한 단순할 때 가장 잘 작동한다.
  - **올바른 데이터를 제공하는 한, 그들이 올바른 일을 할 것이라고 믿을 수 있을 정도로 간단**하다.
  - 또한 너무 **간단하여 자체적으로 로직이 거의 없다.**
  - 예를 들어, save / load effect는 데이터를 디스크로 가져오고 디스크에서 가져 오는 데 필요한 최소한의 작업만을 수행한다.
    - json decode와 같은 데이터 변환을 수행하지 않고, 사용자에게 맡긴다.
    - 테스트는 디스크와의 상호작용하는 번거러움을 종속성에게 맡기고, 데이터의 변환에 대하여 테스트한다.
- load effect의 로직을 save effect로 옮겨 테스트를 진행하면 몇 부분에서 실패를 확인할 수 있다.
  - `effects[0]` 의 효과는 값을 내보냈지만, 그것이 안된다는 것을 알고 있다.
  - `didSave`  플래그가 true로 바뀌지 않았으며 이는 save effect가 호출되지 않았 음을 의미한다.
- **종속성을 가변 필드가있는 간단한 구조체로 설명**하고 **reducer가 해당 구조체에서 이러한 종속성을 사용하도록 강제**함으로 인하여 , **실제 구현을 mock으로 교체**하고  effect를 실행하여 시스템에 피드백할 올바른 값을 생성했거나 전혀 생성하지 않았다고 확인할 수 있다.
- 관심을 갖는 것은 특정 **effect가 호출되었는지 캡처**하고 **reducer에 다시 공급되는 데이터를 캡처하는 것** 이다.

### [Testing the favorite primes load effect](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t1891)

- `testLoadFavoritePrimesFlow` 는 state가 변경되지 않고 effect가 발생하고 있다. 
  - 어떤 effect인지는 모르지만 `loadedFavoritePrimes` effect라고 가정하고 redcuer에서 해당 액션을 실행하고 state가 변경되었으며 추가 effect가 방출되지 않았다고 확인한다.
- 이 테스트를 실행하기 위해 디스크 상태에 의존 할 필요가 없다.
  - 이 effect를 제어 했으므로, 디스크를 완전히 우회하고 데이터를 직접 제공할 수 있다.

```swift
Current.fileClient.load = { _ in
    .sync {
        try! JSONEncoder().encode([2, 31])   
    }
}
```

- 다음으로 수행될 action을 직접 수행하지 않고, `loadButtonTapped` action의 다음 effect를 reducer에 다시 피드백하고자 한다.
  - Effect(store에 다시 피드백하기 위한)를 생성하기 위한 action을 수동으로 구성하지 않는다.
  - 대신 effect를 실행하고 예상한 동작을 생성했음을 확인하고, reducer에 다시 피드백한 다음 새로운 action이 state를 어떻게 변경했는지 확인한다.
  - 테스트 `expectation`을 설정하고 `sink` 를 기다린 다음, `receiveCompletion`에서 `expectation` 을 충족하여 다른 effect를 만들어 내지 않을 것을 확인할 수 있다.

```swift
var nextAction: FavoritePrimesAction!
let receivedCompletion = self.expectation(description: "receivedCompletion")
_ = effects[0].sink(
  receiveCompletion: { _ in receivedCompletion.fulfill() },
  receiveValue: { action in
    nextAction = action
    XCTAssertEqual(action, .loadedFavoritePrimes([2, 31]))
})
self.wait(for: [receivedCompletion], timeout: 0)
```

### [Controlling the counter effect](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t2271)

-  `nthPrime` method는 제어하고자 하는 effect이기에 CounterEnvironment에 추가하도록 한다.
  - mock을 추가하여 API를 사용하지 않고 데이터를 직접 제공할 수 있도록 한다.

```swift
struct CounterEnvironment {
  var nthPrime: (Int) -> Effect<Int?>
}
```

### [Testing the counter effects](https://www.pointfree.co/collections/composable-architecture/testing/ep83-testable-state-management-effects#t2545)

- `testNthPrimeButtonHappyFlow` 는 현재 effect에 대하여 알 수 없는 상태이다.
- `nthPrimeButtonTapped` action에 대한 effect를 실행하고 다음 action이 `nthPrimeResponse` 임을 확인한다.

```swift
_ = effects[0].sink(
  receiveCompletion: { _ in },
  receiveValue: { action in
    XCTAssertEqual(action, .counter(.nthPrimeResponse(3)))
})
```

- Effect가 예상대로 완료되었는 지를 확인하고 reducer로 다시 피드백할 수 있도록 한다.
  - 이때 effect가 다른 queue에서 작업하게 되기에, timeout 시간을 0.01초로 변경한다.
- `testNthPrimeButtonUnhappyFlow` 는 API response가 오지 않았을 경우로, `nthPrime`이  `nil` 을  반환하도록 한다.