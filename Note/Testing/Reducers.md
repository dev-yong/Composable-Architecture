# Testable State Management: Reducers

### [Introduction](https://www.pointfree.co/collections/composable-architecture/testing/ep82-testable-state-management-reducers#t5)

- 우리는 관찰 한 내용을 모든 애플리케이션 아키텍처에서 해결하는 데 매우 중요하다고 생각하는 5 가지 주요 문제로 정리하였다.

  - Architecture의 **기본 단위는 간단한 value type으로 표현가능**해야한다.
    - Solved : **State와 Action은 value type으로 모델링**되어졌다.
  - App **state에 대한 변하는 일관된 단일 방향**으로 이루어져야 하고, **변경의와 observation의 단위은 구성가능한 방법으로 표현**될 수 있어야한다.
    - Solved : **변화는 강력하게 구성가능한 reducer function으로 표현**된다.
  - Architecture는 **모듈식**이여야 한다. 
    - 즉 문자그대로 많은 어플리케이션의 unit을 자체 Swift 모듈로 넣을 수 있어야한다.
    - 그래야 **모든것들과 분리되는 동시에 서로 붙일 수도 있다**.
    - Solved : **State 변경에 대한 관찰**은 구성가능하고 앱의 모든 화면을 자체적으로 실행할 수있는 자체 Swift 모듈로 분할 할 수 있는 **Store 유형을 사용하여 표현**된다.
  - Architecture는 **어디서 그리고 어떻게 Side effect을 실행하는지** 정확히 알려야한다.
    - Solved: Side effects들은 ahirctuecture 내에서 모델링되어질 수 있다.
  - Architecture는 다양한 구성 요소를 테스트하는 방법을 기술해야하고, 이상적으로 이러한 테스트를 작성하려면 최소한의 설정 작업이 필요하다.
    - Not solved yet

### [Recap](https://www.pointfree.co/collections/composable-architecture/testing/ep82-testable-state-management-reducers#t148)

- 적당히 복잡한 응용 프로그램에서 해결해야하는 많은 문제를 보여준다.
    - 여러 화면에 걸쳐 공유된 State가 있으며 한 화면이 해당 state를 변경하면 다른 화면에 즉시 반영되어야 한다.
    - 여러 가지 side effect가 사용되어 application이 복잡해진다. (e.g. network request, save and load)
    - 구현중인 미묘한 논리가 있다. (e.g. API 요청이 진행중인 동안 버튼을 비활성화)
- iOS 커뮤니티의 테스트 문화는 다른 커뮤니티의 경우만큼 강력하지 않다. 
    - 이것의 일부는 타입 시스템을 가진 언어가 컴파일 타임에 많은 기본 버그를 잡을 수 있기 때문에 더 적은 테스트를 요구하는 경향이 때문일 수 있다.
    - 또한 매일 작업하는 프레임 워크가 실제로 테스트를 염두에두고 구축되지 않은 UIKit이라는 사실 때문일 수도 있다.
      - `XCUITest`와 같이 Apple이 제공 한 도구가 있지만 이것은 깨지기 쉽고 느리며 Application의 매우 특정 부분을 테스트하는 것을 목표로 하고 있다.
- 위와 같은 현상들은 iOS 커뮤니티가 UIKit 위에있는 추상화와 아키텍처를 구축하게하여 테스트를 더 쉽게 작성할 수 있도록 하였다.
    - 그럼에도 불구하고, 테스트가 여전히 커뮤니티의 표준이 아니라고 생각한다.
    - 그 이유는, 테스트를 작성하는 데 필요한 작업의 양과 테스트에서 얻을 수있는 깊이와 폭의 단절 때문이었다.
      - 종종 조정이 필요한 많은 객체를 생성하는 것에서부터 관심사를 분리하기 위해 아키텍처에서 사용된 프로토콜에 대한 많은 준수를 생성하는 것까지 모든 테스트를위한 설정 작업이 필요히디.
      - 그리고 이러한 테스트에서 얻는 커버리지는 필요한 설정의 양을 정당화하지 않는다.
      - 테스트 코드가 너무 복잡하여 애플리케이션 자체에서 아무것도 확인하지 않고 테스트 코드가 올바르게 실행되었는지 확인하는 경우가 많다.
- 따라서 테스트가 아키텍처에서 성공하려면 **간단해야하고** **추가 개념의 조정이 거의 필요하지 않으며** 애플리케이션에서 **매우 깊고 미묘한 기능을 캡처 할 수 있어야한다**.
    - Application의 핵심 로직이 올바르게 실행되는지 확인한다.
    - Cross cutting 관심사가 올바르게 구현되었는지 확인한다.
    - Side effect가 실행되고 그 결과가 시스템에 올바르게 피드백되는지 확인한다.
    - 모든 것이 올바른지 확인한다.

### [Testing the prime modal](https://www.pointfree.co/collections/composable-architecture/testing/ep82-testable-state-management-reducers#t408)

  - Application에서 지금 테스트하기 가장 쉬운 부분은 reducer이다.
    - Reducer는 애플리케이션을 현재 State에서 다음 State로 이동하는 한 단계에 불과하고 순수한 함수이기 때문이다.
    - 테스트는 현재 State와 사용자 작업을 입력하고 결과 state를 확고히 하는 것만큼 쉬워야한다.
  - 실제 테스트를 작성하기 위하여 `primeModalReducer` 의 signature를 확인한다.
      - Reducer에 공급하기 위한 변경가능한 `PrimeModalState`와 `PrimeModalAction`이 필요하다. 
      - `PrimeModalAction`의 경우, 현재 카운트를 즐겨 찾기 프라임으로 저장하거나 제거 할 수 있다.

  ```swift
primeModalReducer(state: &<#PrimeModalState#>, action: <#PrimeModalAction#>)
  ```

- 아래의 코드는 빌드는 성공적이겠지만, 테스트의 포괄성을 잃게 된다.
  - `PrimeModalState`에 필드가 추가되고 해당 필드가 `saveFavoritePrimeTapped`의 논리를 실행하기 위해 어떤 방식으로든 사용되면 `primeModalReducer`에서 해당 필드에 발생한 일을 확고히 할 수있는 것을 완전히 놓칠 수 있다.
  - 이상적으로 State에 필드를 추가하면 컴파일러 오류가 발생하므로 해당 필드가 어떻게 변경되었는지 고려해야한다.
  - 따라서, 이것은 올바른 방법이 아니다.

```swift
func testExample() throws {
    var state = (count: 2, favoritePrimes: [3, 5])
    primeModalReducer(state: &state, action: .saveFavoritePrimeTapped)
    XCTAssertEqual(state.count, 2)
    XCTAssertEqual(state.favoritePrimes, [3, 5, 2])
}
```

- 방법 중 한 가지는 튜플에 저장하는 state를 명시적으로 분해하는 것이다.
  - 만일 PrimeModalState에 변경이 있다면, compile시 실패할 것이며 그에 맞게 test를 변경할 수 밖에 없다.

```swift
func testExample() throws {
    var state = (count: 2, favoritePrimes: [3, 5])
    primeModalReducer(state: &state, action: .saveFavoritePrimeTapped)
    
    let (count, favoritePrimes) = state
    XCTAssertEqual(count, 2)
    XCTAssertEqual(favoritePrimes, [3, 5, 2])
}
```

- 테스트의 복잡성은 State vlaue가 갖는 필드의 수에 비례한다.
  - 테스트할 때 플러그인할 가변 값을 변이가 생긴 후에 대한 상태 값에 대하여 확고히 하기만 하면 된다. 
  - 다른 설정은 필요로 하지 않는다.

### [Testing favorite primes](https://www.pointfree.co/collections/composable-architecture/testing/ep82-testable-state-management-reducers#t834)

- Favorite primes reducer에 대한 테스트를 작성하기 위하여 해당 signature를 확인한다.

```swift
favoritePrimesReducer(
  state: &<#[Int]#>,
  action: <#FavoritePrimesAction#>
)
```

- `saveButtonTapped` action은 state에 대한 변경 없이 디스크에 저장하기만을 하는 action이며, 따라서 side effect가 존재한다.
  - 하지만 아래의 코드에서는 해당 Side Effect로 인하여 어떠한 일이 발생하였으며, 어떠한 Side Effect인지에 대한 확인을 하지 않는다.

```swift
func testSaveButtonTapped() {
    var state = [2, 3, 5, 7]
    
    let effects = favoritePrimesReducer(
        state: &state,
        action: .saveButtonTapped
    )
    
    XCTAssertEqual(state, [2, 3, 5, 7])
    XCTAssertEqual(effects.count, 1)
}
```

- Favorite prime을 load하는 전체적인 흐름을 테스트하는 것이 더욱 좋기 때문에 `loadButtonTapped` 과  `loadedFavoritePrimes` action과 함께 테스트하도록 한다.
  - Reducer의 두번째 호출에서 덮어 쓸 수 있도록 변경 가능한 `effects` 를 유지해야하는 지저분함이 있다.
  - Reducer에 의하여 effect가 반환되었음을 확인할 뿐, 해당 내용에 대해선 아무것도 확인하고 있지 않다.
  - Effect의 결과를 reducer에 명시적으로 피드해야하는 문제가 있다.

```swift
 func testLoadFavoritePrimesFlow() {
    var state = [2, 3, 5, 7]
    
    var effects = favoritePrimesReducer(
        state: &state,
        action: .loadButtonTapped
    )

     XCTAssertEqual(state, [2, 3, 5, 7])
     XCTAssertEqual(effects.count, 1)

     effects = favoritePrimesReducer(
        state: &state,
        action: .loadedFavoritePrimes([2, 31])
     )

     XCTAssertEqual(state, [2, 31])
     XCTAssert(effects.isEmpty)
}
```

### [Testing the counter](https://www.pointfree.co/collections/composable-architecture/testing/ep82-testable-state-management-reducers#t1158)

- `counterViewState` 는 `CounterViewState` 와 `CounterViewAction` 을 input으로 받고있다.
- `incrTapped` action에 대한 counterViewReducer 테스트를 위하여 CounterViewState를 Equatable를 따르게 한다.
- nthPrime 과 연관된 흐름에는 asyncrhonous한 side effect가 존재하고 있다.
  - 반환된 effect에 대해 아무것도 확인할 수는 없지만 어느 시점에서 API 요청이 완료되고 그 결과가 저장소로 다시 공급된다는 것을 알고 있다.
  - 현재는 nthPrimeResponse 작업으로 감속기를 다시 호출하여 수동으로 작업을수행 할 수 있다.

```swift
func testNthPrimeButtonFlow() {
    var state = CounterViewState(
        alertNthPrime: nil,
        count: 2,
        favoritePrimes: [3, 5],
        isNthPrimeButtonDisabled: false
    )
    // 1. 사용자가 nthPrimeButton을 tap한다.
    var effects = counterViewReducer(&state, .counter(.nthPrimeButtonTapped))
    
    XCTAssertEqual(
        state,
        CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: true
        )
    )
    XCTAssertEqual(effects.count, 1)
    
  // 2. API response를 받는다.
    effects = counterViewReducer(&state, .counter(.nthPrimeResponse(3)))
    
    XCTAssertEqual(
        state,
        CounterViewState(
            alertNthPrime: PrimeAlert(prime: 3),
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )
    )
    XCTAssertTrue(effects.isEmpty)
    
  // 3. 사용자가 alert를 dismiss한다.
    effects = counterViewReducer(&state, .counter(.alertDismissButtonTapped))
    
    XCTAssertEqual(
        state,
        CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )
    )
    XCTAssertTrue(effects.isEmpty)
}
```

### [Unhappy paths and integration tests](https://www.pointfree.co/collections/composable-architecture/testing/ep82-testable-state-management-reducers#t1759)

- 여태까지의 테스트는 성공하는 경우(Happy)에 대해서만 테스트를 하였으므로, 실패할 수 있는 경우(Unhappy)에 대한 테스트도 진행하여야 한다.
  - nthPrime flow의 경우, API response가 오지 않았을 경우가 발생할 수 있다.
- Counter와 PrimeModal이 제대로 통합되었는지 확인하는 통합 스타일 테스트가 필요로 하다.

