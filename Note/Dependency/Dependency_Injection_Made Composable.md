# Dependency Injection Made Composable

### [Introduction](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t40)

- Side effect와 Testability를 `Environment` 를 이용하여 조화롭게할 수 있다.
- `Environment`는 **Side Effect를 야기하는 모든 것을 저장할 수 있는 단일 공간**을 제공하며, environment에 **저장되지 않는 한 모든 의존성의 사용을 금지**한다.
  - 이것은 의존성을 접근하는 일관적인 방법을 제공한다.
  - 테스트, 플레이 그라운드에서 제어된 의존성에 대한 의존성을 바꾸는 것이 매우 쉬워지며, 원하면 실제 어플리케이션을 실행할 때에도 mock 을 사용할 수 있다.

### [Effects recap](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t137)

- Composable Architecture에서 side effects는 reducer로부터 effect value 배열을 반환하여 표현되고, 그런 다음 store는 모든 effect를 가져오고 수행하는 책임을 갖는다.
```swift
public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]
```

- `Effect` 는 Cominedㅔ서 제공하는 `Publisher` 를 따르는 custom type이다.

```swift
public struct Effect<Output>: Publisher {
    
    public typealias Failure = Never
    
    public let publisher: AnyPublisher<Output, Failure>
    
    public init (
        publisher: AnyPublisher<Output, Failure>
    ) {
        self.publisher = publisher
    }

    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Failure == S.Failure, Output == S.Input {
      self.publisher.receive(
        subscriber: subscriber
      )
    }
    
}
```

- 그렇기 때문에 effect의 무거운 작업을 위해 Combine을 활용할 수 있다.

  - network request, decoding, timer 뿐만아니라 모든 publisher의 변형(e.g. `map`, `zip`, `flatMap` , `filter` 등)을 이용할 수 있다.

- `Effect` 는 Publisher API를 오염시키지 않고 편리한 helper를 추가하기 위하여 간단하게 기존의 publisher를 감쌌다

  - `fireAndForget`이 그 예시 중 하나이다.

    - 이를 통해 일부 작업을 수행해야하지만 시스템에 데이터를 다시 공급할 필요가 없는 side effect를 발생시킬 수 있다.

    ``` swift
    extension Effect {
        public static func fireAndForget(
            work: @escaping () -> Void
        ) -> Effect {
            return Deferred { () -> Empty<Output, Never> in
                work()
                return Empty(completeImmediately: true)
            }.eraseToEffect()
        }
    }
    ```

  - Synchronous 작업을 수행할 수 있는 effect helper 또한 지니고 있다.

    - 이를 통하여 외부 세계와 상호작용할 필요가 있지만, asynchronous할 필요는 없다.
    - 디스크로부터 데이터를 불러오는 effect를 수행할 경우 사용할 수 있다.

    ```swift
    extension Effect {
      public static func sync(work: @escaping () -> Output) -> Effect {
        return Deferred {
          Just(work())
        }.eraseToEffect()
      }
    }
    ```

  - 일반적으로 Publisher를 구성하고 변환하기 위해 Combine에서 API를 자유롭게 사용할 수 있으며, 작업이 끝나면 `eraseToEffect` helper를 사용하여 Publisher를 Effect로 변환 할 수 있다.

    ```swift
    extension Publisher where Failure == Never {
      public func eraseToEffect() -> Effect<Output> {
        return Effect(publisher: self.eraseToAnyPublisher())
      }
    }
    ```

- 이러한  Effect를 애플리케이션에 적용하는 방법은 reducer에서 생성하고 반환하는 것이다.

```swift
public func counterReducer(
  state: inout CounterState,
  action: CounterAction
) -> [Effect<CounterAction>] {
  switch action {
  case .decrTapped:
    state.count -= 1
    return [
      .fireAndForget {
        // Escaping closure captures ‘inout’ parameter ‘state’
        print(state.count) 
      }
    ]
}
```

- escaping closure 내부에서 inout 상태 변수에 액세스하려고하기 때문에 지금은 작동하지 않는다.  이 오류는 매우 좋은 오류이다.
  - 만일 이 clsoure가  10초뒤에 실행이 된다면 원치 않은 결과물을 확인하게 될 것이고, 아키텍쳐는 이러한 것을 방지하고자 하였다.
- 하지만, state에 대한 immutable reference를 갖게 된다면 이상없이 수행될 것이다.

```swift
case .decrTapped:
  state.count -= 1
  let count = state.count
  return [
    .fireAndForget {
      print(count)
    }
  ]
```

### [Environment recap](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t511)

- Reducer자체로는 할 수 없는 바깥 세상과 상호작용이 필요한 작업을 Effect는 수행할 수 있다.
- 그러나 side effect도 테스트하기 어렵기 때문에 effect를 제어하기 위하여 environment를 이용하였다.
- Environment 테크닉을 차용하기 위하여 어플리케이션이 접근해야하는 모든 의존성을 지니는 struct를 정의한다.
  - 예를 들어, `Counter` 모듈은 `nth prim` 계산하기 위한 함수만 접근하면 되며, 일반적으로 Wolfram alpha로 알려진 강력한 컴퓨팅 플랫폼에 네트워크 요청을 보낸다.

```swift
struct CounterEnvironment {
  var nthPrime: (Int) -> Effect<Int?>
}
```

- Live 의존성을 mock 의존성으로 쉽게 교체하기 위하여 이 필드를 `var ` 로 만든다.
- 이 기술의 일부분으로 우리는 정적으로 표현된 Environment의 live와 mock 구현체에 대한 쉬운 접근을 제공하도록 한다.

```swift
extension CounterEnvironment {
	 static let live = CounterEnvironment(nthPrime: Counter.nthPrime)
   static let mock = CounterEnvironment(nthPrime: { _ in .sync { 17 }})
}
```

- Live를 기본으로 하는 이 environment의 global mutal 인스턴스를 정의한다.
- 그런 다음 Environment에 저장되지 않는 한 종속성에 도달하지 않도록 강제한다.
  - 예를 들어 "nth prime"이 무엇인지 묻는 버튼을 탭하면 `Current`  environment에 도달하여 효과를 실행한다.

```swift
case .nthPrimeButtonTapped:
  state.isNthPrimeButtonDisabled = true
  return [
    Current.nthPrime(state.count)
      .map(CounterAction.nthPrimeResponse)
      .receive(on: DispatchQueue.main)
      .eraseToEffect()
]
```

- 이 mutable variable은 이상하게 보일 수 있지만, 이를 통해 전체 environment을 한 줄로 쉽게 모의할 수 있다.

```swift
class CounterTests: XCTestCase {
  override func setUp() {
    super.setUp()
    Current = .mock
  }
}
```

- 이것은 모든 테스트가 통제된 envrionment에서 수행됨을 보장할 수 있는 것을 뜻하지만, 의존성 중 하나를 다시 작성하여 각 테스트 케이스에서 환경을 추가로 조정할 수도 있다.

```swift
func testNthPrimeButtonHappyFlow() {
  Current.nthPrime = { _ in .sync { 17 } }

  assert(
```

### [Current problems](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t679)

- 하지만, Environment가 문제가 없다는 것은 아니다.

- 아마도 가장 명백한 문제는 우리가 정의한 각 Envrionemt가 그 자체의 모듈에 살고 있으므로 완전히 분리되어 있다는 것이다.

- 구성된 Reducer 접근 방식의 이점 중 하나는 애플리케이션의 여러 계층을 한 번에 실행하는 통합과 유사한 테스트를 작성할 수 있다는 것이다.

  - 예를들어, coutner feature와 prime modal feature가 적절하게 통합된테스트를 작성하였었다.
  - 특히, 우리는 사용자가 카운터를 1씩 증가시킨 다음 선호하는 소수에서 해당 숫자를 추가 및 제거하는 아이디어를 시뮬레이션하였다.

  ```swift
  func testPrimeModal() {
    assert(
      initialValue: CounterViewState(
        count: 1,
        favoritePrimes: [3, 5]
      ),
      reducer: counterViewReducer,
      steps:
      Step(.send, .counter(.incrTapped)) {
        $0.count = 2
      },
      Step(.send, .primeModal(.saveFavoritePrimeTapped)) {
        $0.favoritePrimes = [3, 5, 2]
      },
      Step(.send, .primeModal(.removeFavoritePrimeTapped)) {
        $0.favoritePrimes = [3, 5]
      }
    )
  }
  ```

  - 이것은 믿을 수 없을 정도로 강력하며, 기본적으로 composable reducer를 통하여 가능한 일이다.

- 하지만, 이 단계의 스크립트에서는 어떠한 effect도 테스트하지 않기 때문에, 우리는 큰 그림을 볼수 없다.

  - 현재 오로지 `Counter` 모듈만이 모든 effect를 지니고 있고, `PrimeModal` 은 어떠한 것도 지니고 있지 않기 때문에, 여기서 일어나는 문제가 무엇인지 확인하기 어렵다.
  - 모든 effect에 대하여 모의하기 위하여, `Current = .mock` 을 추가한다.

- 그러나 모든 것을 하나의 큰 `appReducer`로 함께 구성하는 main app target에 대한 통합 테스트를 작성하는 것을 백업하고 생각하면 무엇이 필요한지 더 잘 이해할 수 있을 것이다.
- 통합테스트를 작성하려면 모든 모듈을 import한다. 
- `testIntegration` 테스트에서 우리는 완벽히 제어된 envirnment에 있는 지 확인하고 싶으므로, 각 모듈들의 environment를 모의해야한다.
  
  - 이것은 Counter, FavoritePrimses 모듈 모두를 의미한다.

```swift
class PrimeTimeTests: XCTestCase {
  func testIntegration() {
    Counter.Current = .mock
    FavoritePrimes.Current = .mock
  }
}
```

- 이 작업을 올바르게 수행했는지 확인하기 위하여 **컴파일러에서 정적 도움을 받지 못하고 있다**.
  - 애플리케이션에 점점 더 많은 기능을 추가함에 따라 기능을 담을 새로운 모듈을 만들 것이며, 각 모듈은 환경을 갖게 될 것이며, 그 어떤 것도 우리가 그러한 환경을 모의하도록 강요하지 않을 것이다.
  -  테스트 중에 live 의존성을 호출 할 위험이 있다.
- 이 접근 방식의 또 다른 문제는 모듈간에 **의존성을 공유하기가 쉽지 않다**는 것이다.
  - 예를 들어, `FavoritePrimes`  모듈에는 데이터를 디스크에 저장하고 로드하는 데 사용한 `FileClient`가 있다.
  - 다른 모듈에서 이와 동일한 의존성을 원하면 새 `FileClient`를 구성하여 해당 모듈에서 사용해야 할 가능성이 크다. 그렇지 않으면, 더 높은 수준에서 조정을 해야한다.
  - 예를 들어, AppDelegate에서 `FavoritePrimes` 모듈과 다른 모듈이 모두 동일한 `File Client`를 공유하는지 확인하기 위해 추가 작업을 수행 할 수 있다.
  - 또한 모든 모듈이 동일한 종속성으로 테스트되고 있는지 확인하기 위해 테스트에서 동일한 작업을 수행해야한다.
  - 마지막으로, **모듈 내부의 모든 인스턴스가 해당 Envrionment에서 하나의 실제 environment만 사용할 수 있다는 것**이다.
    - 예를 들어 Wolfram API를 사용하여 계산을 수행하는 Counter view를 생성할 수 없으며, 계산을 수행하기 위해 다른 API를 사용하는 counter view도 만들 수 없다.
    - 이것은 각 모듈의 코드를 필요보다 유연하게 만든다.
- 위의 모든 문제들을 해결하기 위한 방법은 **의존성을 필요로하는 함수에 명시적으로 의존성을 전달**하는 것이다.
  - 함수에 작업을 수행하는 데 필요한 모든 것을 제공하면, 테스트하고 제어하는 것이 간단하다.
- 그러나 이것이 항상 가능하거나 쉬운 것은 아니다. 
  - 실제 코드 기반에서는 원하는대로 종속성을 전달하는 것이 엄청나게 어렵거나 불가능할 수도 있다.
  - 어렵게 만드는 레거시 코드가 있거나 원하는 작업을 수행하지 못하게하는 추상화 계층이있을 수 있다.
  - Environment를 통하여 모든 코드베이스에서 즉시 일부 테스트 가능성과 종속성을 제어 할 수 있다.

### [Environment in the reducer](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t1012)

- Composable Architecture는 전체 애플리케이션에 걸쳐 기능을 구축 할 수있는 일관된 단일 방식을 제공한다. 

  - 아키텍처가 environment를 인식하도록 할 수 있다면 자동으로 사용할 수 있기 때문에 global architecture에 접근 할 필요가 없다. 
- **작업을 시작하는 곳은 Reducer**이다. 
  - Reducer는 나중에 Store에서 실행되는 Effect를 생성하는 역할을하기 때문이다.
  - 이러한 effect를 제어할 수 있으려면 제어 가능한 방식으로 종속성에 접근해야한다.
- 이전에는 모듈의 envrionmet에 직접 접근했지만 대신 reducer 내부에서 사용할 수있는 environment가 있다면 어떨까?
  - 이 `Environment` generic은 로직을 강화하는 effect를 생성하기 위하여 reducer에 필요한 종속성을 제공 할 수있는 기회를 제공한다.

```swift
typealias Reducer<Value, Action, Environment> = (inout Value, Action, Environment) -> [Effect<Action>]
```

- 변경된 `Reducer` signature는 `combine` 함수에서 첫 컴파일 에러를 확인할 수 있다.
  - 이를 수정하기 위해 environment generic을 도입하고 각 하위 reducer에게 전달하면 된다.

```swift
public func combine<Value, Action, Environment>(
  _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
  return { value, action, environment in
    let effects = reducers.flatMap { $0(&value, action, environment) }
    return effects
  }
}
```

- 다음 에러는 `pullback` 에서 발생한다. 지금 문제가 있는 건 새로운 environment를 다시 설명해야 하기 때문에 문제가 존재한다.
  - 가장 손쉽게 해결하는 방법은 `Environment` generic을 도입하고 environment를 local reducer에 전달하는 것이다.
  - Reducer에 대한 pullback 작업은 local reducer를 global reducer로 변환하는 것이 전부였다.
    - 이는 모듈화에 편리하였다. 
    - 기능이 실제로 관심을 갖는 도메인 유형만 포함하는 모듈로 기능을 분할 한 다음, App Target이 해당 도메인을 전체 앱 도메인으로 결합 할 수 있기 때문이다.
- `pullback` 의 모듈화를 유지하고 global environment의 관련되지 않은 디테일에서 더 많은 **local environment을 분리시키기 위하여 environemt가 변환될 수 있기**를 원한다.
  - Local reducer를 실행하려고 할 때 local environment를 제공해야 한다. 
  - 현재 가지고 있는 global environment를 local environment로 변환할 방법이 필요하고 바로 거기에서 pullback에 전달해야하는 변환의 형태를 정의할 수 있다.
    - `environment` 변환의 방향은 `value` 및 `action` 변환의 방향과 동일하다.
    - 세 가지 모두 Global에서 Local로 이동한다.
    - 따라서 이 변환은 각 generic에서 여전히 contravariant이다.
  - 또한, KeyPath나 CasePath 대신 일반 함수을 따라 environmet를 pullback하는 것이 전적으로 괜찮은 방법이다. 
    - KeyPath, CasePath는 state와 action을 분리하고 다시 연결하기 위한 강력한 도구가 필요하기 때문이다. 
    - 그러나 environment를 위해 우리는 단지 global에서 local environment를 투영하기만 하면 된다.

```swift
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>,
    environemnt: @escaping (GlobalEnvironment) -> LocalEnvironment
)
```

### [Environment in the store](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t1414)

- 아직 `Store` 에서 많은 에러들이 존재한다.
- 먼저 `Reducer` 는  3개의 generic을 갖고 environment generic을 위하여 Store에 generic을 추가하도록 한다.
  - `Store` 의 모양과 `Reducer` 의 모양이 일치하는 것처럼 보인다.

```swift
public final class Store<Value, Action, Environment>: ObservableObject {
  private let reducer: Reducer<Value, Action, Environment>
```

- `send` 메소드에서 에러가 발생한다.

  - environment를 제공하지 않고 reducer를 호출하려고 하기 때문이다.
  -  `Store` 를 만들 때 environment를 제공하고 필드로 environment를 붙잡고 작업이 발생할 때마다 reducer로 전달할 수 있다.

- `view` method는 local domain으로 노출하는 store로 변환할 수 있다.

  - 이것은 SwiftUI View에서 store를 가져와서 부모의 state와 action의 일부만을 필요로 하는 더 작은 view로 전달하는 방법이다.
- 모두 global store를 local store로 변환하는 것이므로 여기에 있는 value 및 action 변환과 함께 또 다른 변환을 제공해야한다.
  - Local store의 reducer에서는 실질적으로 local environment를 사용하고 있지 않음을 유의해야한다.

```swift
public func view<LocalValue, LocalAction, LocalEnvironment>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action,
        environment toLocalEnvironment: @escaping (Environment) -> LocalEnvironment
    ) -> Store<LocalValue, LocalAction, LocalEnvironment> {
        
        let localStore = Store<LocalValue, LocalAction, LocalEnvironment>(
            initialValue: toLocalValue(self.value),
            reducer: { localValue, localAction, _ in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            },
            environment: toLocalEnvironment(self.environment)
        )
        self.viewCancellableBag.insert(
            self.$value.sink { [weak localStore] (newValue) in
                localStore?.value = toLocalValue(newValue)
            }
        )
        return localStore
    }
```

### [Erasing the environment from the store](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep91-dependency-injection-made-composable#t1664)

- `Store`에서 `view`  메소드를 구현하는 것은 매우 이상하고 우리가 제대로하고 있는지 아닌지 의문을 갖게 한다.
  - 의미있는 방식으로 사용되지는 않았지만 `view` 메소드에서 environment를 고려해야 했다.
- 전체적인 개념으로서, **store는 environment와 거의 관련이 없다**.
  - `Store` 의 사용자들은 오로지 state value를 꺼내오는 것과 action을 보내는 것만을 고려하면 된다. 
  - 그들은 절대 environment에 접근하지 않고  내부에서 사용되는 것에 대하여 알 필요가 없다. 
- `Store` 에서 environment type을 지우고자 한다.
  - 즉 generic을 지우고 environmet의 디테일을 public으로 노출하는 것 대신, class의 구현체 않으로 숨기는 것이다.
  - `Reducer` 의 envrionment를 `Any` 로 만들고 force casting을 통하여 environment를 변환한다.
  - Environment는 순전히 `Store` 내부의 구현 세부 사항이며 모든 environment의 변환이 이미 reducer에 적용되어 있다.

```swift
public init<Environment>(
  initialValue: Value,
  reducer: @escaping Reducer<Value, Action, Environment>,
  environment: Environment
) {
  self.reducer = { value, action, environment in
    reducer(&value, action, environment as! Environment)
  }
  self.value = initialValue
  self.environment = environment
}
```

