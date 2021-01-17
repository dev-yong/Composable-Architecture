# The Combine Framework and Effects

### [The Effect type: a quick recap](https://www.pointfree.co/collections/composable-architecture/side-effects/ep80-the-combine-framework-and-effects-part-1#t138)

```swift
public struct Effect<A> {
  public let run: (@escaping (A) -> Void) -> Void
}
```

- `(@escaping (A) -> Void) -> Void` 은 value의 전달에 대한 아이디어를 갖는 매우 간단한 타입이며, 완벽하게 asynchronous하다.

- 따라서, 아래의 코드는 약 2초 이후에 결과물을 출력하게 된다.

  ```swift
  let anIntInTwoSeconds = Effect<Int> { callback in
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      callback(42)
    }
  }
  anIntInTwoSeconds.run { print($0) }
  ```

> - 즉각적으로 동작하지 않는 이 속성을 "**Laziness**" 이라고 한다.
>
>   - 작업은 오로지 요청됬을 때에만 수행된다.
>
> - "Laziness"의 반대는 "**Eager**"이다.
>
>   - 생성되어지는 순간에 바로 수행한다.

- `Effect` 는 내부에있는 값을 변환하는  `map`  operation을 지원하지만, 더욱 많은 것들을 생각할 수 있다.
  - `zip` : 많은 effect들을 parallele하게 수행하고 값들을 하나의 값으로 모은다.
  - `flatMap` : asynchronous 값을 함께 시퀀스 할 수 있다.
  - Input으로 effect를 가져오고 Output으로 effect를 반환하는 함수인 더 복잡한 "Higher-order effects"를 고려할 수 있다.
- Combine은 Effect 타입이 표현할 수 있는 모든 것들을 표현할 수 있을 뿐만 아니라, 더욱 많은 것을 표현할 수 있다.

### [The Combine-Effect Correspondence](https://www.pointfree.co/collections/composable-architecture/side-effects/ep80-the-combine-framework-and-effects-part-1#t315)

- Combine framework는 **Publisher**와 **Subscriber** 라는 두 가지의 개념이 있다.

  - **Pulbihser** 는 값들에 대하여 관심있어하는 것들에게 값들을 제공할 수 있는 타입이다.

    - 이것은 `Effect` 가 하는 것과 같지만, publishers는 더욱 많은 부가 기능들을 제공한다.

  - **Subscriber** 는 값을 받을 수 있는 타입이다.

    - 이것은 `Effect` 의 세계에서는 존재하는 개념의 이름을 갖고 있지 않다.
    - 하지만, 가장 밀접한 개념으로는 'effect가 작동하도록 하기 위하여 effect에 대한 `run` 을 호출하는 것'이다.
    - Combine에서는 cancellation과 demand 등을 지원하기 위하여 subscriber라는 개념을 제공한다.
    - **Cancellation** 은 subscriber가 모든 미래의 값들을 얻지 못하도록 할 수 있다.
    - **Demand** 는 subscriber가 publisher에게 얼마나 더 많은 값들을 받아야 하는가 에 대하여 알릴 수 있도록 한다.

### [Publishers](https://www.pointfree.co/collections/composable-architecture/side-effects/ep80-the-combine-framework-and-effects-part-1#t354)

- Combine의 대부분의 개념들은 concrete 타입 대신 protocol로 이루어져 있다.

```swift
public protocol Publisher {

    associatedtype Output
    associatedtype Failure : Error

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}
```

#### AnyPublisher

- 이러한 assocatedtype이 있는 protocol의 결함으로 인해 Combine은 `AnyPublisher`라는 `Publisher`  protocol의 구체적인 구현체를 제공한다.
  - Protocol에 대해 "any" wrapper (a.k.a type erased wrapper)를 제공하는 것이 매우 널리 사용되므로 사용자 지정 준수를 직접 만들지 않고도 protocol의 인스턴스를 쉽게 인스턴스화 할 수 있다.

```swift
AnyPublisher.init(_ publisher: Publisher)
```

- `AnyPublisher` 는 pulbisher를 갖는 하나의 initializer만 제공을 한다. `Pulbihser` protocol을 따르는 새로운 유형을 만들지 않고 publisher를 생성하기 위하여 또다른 구체적인 구현체인 `Future` 를 이용하도록 한다.

#### Future

```swift
final public class Future<Output, Failure> : Publisher where Failure : Error {

    public typealias Promise = (Result<Output, Failure>) -> Void

    public init(
      _ attemptToFulfill: @escaping (@escaping Future<Output, Failure>.Promise) -> Void
    )
    final public func receive<S>(subscriber: S) 
  		where Output == S.Input, Failure == S.Failure, S : Subscriber
}
```

- `Effect` 타입에서 그러하였던 것처럼 `Future` 도 callback-based initializer 로 이루어져 있다.
  - Result value를 호출할 수 잇는 callback을 제공한다.
  - Future는 값으로 success할 수 있거나 fail할 수 있기에 result를 사용한다.
  - 따라서, succss와 fail에 대한 type을 지정해야한다.
  - `Effect` 에서 작성한 코드와 유사한 형태를 띄고 있다.

```swift
let aFutureInt = Future<Int, Never> { callback in
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    callback(.success(42))
  }
}
```

### [Subscribers](https://www.pointfree.co/collections/composable-architecture/side-effects/ep80-the-combine-framework-and-effects-part-1#t622)

- 미래의 값을 얻기 위하여 subscribe해야한다.
  - 이것은 effect value를 `run`  하는 것과 유사하지만,  `subscribe` 한다.
  - subscribe할 때 선택의 폭이 더 넓다.
- **`Publisher`** 는, `Future` 와 같은, **연관되어진 누군가에게 값을 전달**하고, **`Subscriber` 타입은 값을 받는다.**
  - `Subscriber` 를 제공함으로써 어떻게 값을 받고 값으로 무엇인 가를 할 수 있다.

```swift
public protocol Subscriber {

    associatedtype Input
    associatedtype Failure : Error

    func receive(subscription: Subscription)
    func receive(_ input: Self.Input) -> Subscribers.Demand
    func receive(completion: Subscribers.Completion<Self.Failure>)
}
```

- `Subscriber` 도 `Publisher` 와 마찬가지로 protocol이다.
- Combine에서는 `AnySubscriber` 라는 구체적인 구현체를 제공한다.

```swift
public struct AnySubscriber<Input, Failure> : Subscriber where Failure : Error {

    public init(
      receiveSubscription: ((Subscription) -> Void)? = nil,
      receiveValue: ((Input) -> Subscribers.Demand)? = nil,
      receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil
    )
  
  	...
}
```

- `receiveSubscription` 
  - subscriber가 publisher에 연결되는 순간, 이것은 `Subscription` 객체를 넘겨받았다는 것으로 표현된다.
  - **`Subscription`** 객체를 이용하여 **publisher로부터 원하는 값의 수를 알릴 수 있다**.
- `receiveValue` 
  - pulibhser가 값을 전달하는 순간, 그 값으로 무엇인 가를 할 수 있다.
  - **`Demand`** 값을 반환해야하므로, **publisher에게 원하는 값이 얼마나 더 있는 지 알려줄 수 있다.**
- `receiveCompletion` 
  - Publihser가 완료하는 순간, completion value를 전달한다.
  - Completion은 성공적으로 끝났거나 실패와 함께 끝났음을 의미한다.

#### sink

- Subscriber의 모든 기능이 필요하지 않는 이상,  `AnySubscriber` 보다 더욱 간편하게 사용 가능한  `sink` 가 존재한다.

```swift
func sink(
  receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void),
  receiveValue: @escaping ((Self.Output) -> Void)
) -> AnyCancellable

aFutureInt.sink { value in
  	print(value)
}
```

- 이것은 기본적으로 effect를 위하여 `run` 하는 것과 유사하다.
- 하지만, `sink` 는 실제로 어떠한 것(**`AnyCanellable`**)을 반환하기 때문에 상기의 코드만으로는 작업을 수행할 수 없다. 
  - 반환되는 값은 **sink로 전달되어지는 미래의 값에 대하여 `cancel`을 할 수 있다.**
  - 그리고 그 반환 값을 유지하지 않기 때문에 즉시 할당이 취소되고 subscribe이 cancel된다.

```swift
let cancellable = aFutureInt.sink { value in
  	print(value)
}
cancellable.cancel()
```

### [Eagerness vs. laziness](https://www.pointfree.co/collections/composable-architecture/side-effects/ep80-the-combine-framework-and-effects-part-1#t978)

- `Effect` 의 모든 인스턴스를 `Future` 로 바꾸고, `run` 을 `sink` 로 바꿀 수 있다.
- 아직은 몇 가지의 문제가 있어 완벽하게 바꿀수는 없다.
  - `Future` 를 cancel되었지만, print구문이 출력되는 것을 볼 수 있다.
  - 또한, `Future` 를 sink하지 않더라도 print구문이 출력되는 것을 볼 수 있다.
  - 이러한 현사은 `Future` 가 **Eager Publisher**이기 때문에 발생한다.
- **Eager Publisher**란, subscribe할 때가 아니라 **생성되는 순간 작업을 시작**한다는 의미이다.

```swift
let aFutureInt = Future<Int, Never> { callback in
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    print("Hello from inside the future!")
    callback(.success(42))
  }
}

// 1. Cancel, "Hello from inside the future!"
let cancellable = aFutureInt.sink { int in
  print(int)
} 
cancellable.cancel()

// 2. None, "Hello from inside the future!"
//let cancellable = aFutureInt.sink { int in
//  print(int)
//} 
//cancellable.cancel()
```

- Reducer의 장점은 user action에 의하여 주어지면 apllication의 현재 state를 바꾸는 pure fucntion이며, store에서 수행되어질 effect 배열을 반환하는 것이다. 
  - 만일 `Future` 를 사용한다면 reducer가 호출되는 순간 작업이 수행될 것이다.
- **`Deferred` 를 이용하여 Eager publisher를 lazy publisher로 바꿀 수 있다.**

### [Subjects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep80-the-combine-framework-and-effects-part-1#t1154)

- `Future` 는 나중에 제공할 수 있는 단일의 value를 나타낼 뿐,  여러 value를 전달할 수는 없다.
  - "42" 만을 전달하고 이후의 값은 전달할 수 없다.

```swift
let aFutureInt = Deferred {
  Future<Int, Never> { callback in
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      print("Hello from inside the future!")
      callback(.success(42))
      callback(.success(1729))
    }
  }
}
```

- Socket connection과 같은 effect에서는 socket connection의 모든 값들이 reducer로 전달되어져야한다. 
  - 즉, 여러 value를 전달할 수 있어야 한다.
- `Subject` 를 이용하여 여러 value를 전송하여 subscriber에게 알릴 수 있다.
  - `Subject`는  `Publisher`, `Subscriber` 와 마찬가지로 protocol이다.
  - `PassthroughSubject`와 `CurrentValueSubject`를 기본적으로 제공해준다.
  - `CurrenvalueSubject` 는 초기값을 갖을 수 있으며 subject가 emit한 가장 최신의 값에 접근을 할 수 있는 반면, `PassthroughSubject` 는 subscribe를 통해서만 접근할 수 있다.

### [Effect as a Combine publisher](https://www.pointfree.co/collections/composable-architecture/side-effects/ep81-the-combine-framework-and-effects-part-2#t87)

- `AnyPublisher` 구체적인 적합성을 사용할 수 있지만, effect 특정한 helper와 확장을 추가하기 위하여 자체 명명된 타입을 갖는 것이 편리할 것 이다.
- `Effect` 의 유일한 목적은 궁극적으로 store로 피드백되는 action을 생산하는 것이다.
- 네트워크 요청과 같은 Effect error가 발생하더라도 여전히 action을 생성해야한다.
  - 따라서, effect는 **실패를 표시하기 위해 작업 내에 Result 값을 넣을** 수 있지만 **Effect Publisher 자체는 실패 할 수 없다**.
- `AnyPublisher`와 마찬가지로 publisher를 둘러싼 wrapper 역할을 하고자 한다.
- `Effect`  subscribe에 대하여 저장하기 위해 `Cancellable` 배열을 추가한다.
  - 또한, `Cancellable` 은 protocol로 `Equatable` 을 따를 수 없기에 `AnyCancellable` wrapper class를 이용한다.

```swift
private var effectCancellbaleBag = Set<AnyCancellable>()
public func send(_ action: Action) {
    let effects = self.reducer(&self.value, action)
    effects.forEach {
        var effectCancellable: AnyCancellable!
        effectCancellable = $0.sink(
            receiveCompletion: { [weak self] _ in
                self?.effectCancellbaleBag.remove(effectCancellable)
            },
            receiveValue: self.send
        )
        self.effectCancellbaleBag.insert(effectCancellable)
    }
}
```

### [Pulling back reducers with publishers](https://www.pointfree.co/collections/composable-architecture/side-effects/ep81-the-combine-framework-and-effects-part-2#t511)

- `pullback` 은 local state와 action에서 작동하는 reducer가 필요하며 더 많은  global state와 action에 대하여 작동하도록 되돌릴 수 있다.
- Effect가 적합한 곳은 local reducer가 local effect를 생성 할 때이다. 
- Local effect는 store에게 다시 local caction을 반환할 수 있기 때문에 local action을 더 많은 global 로 감싸야한다.

```swift
return localEffects.map { localEffect in
  Effect { callback in
    localEffect.sink { localAction in // 🛑
      var globalAction = globalAction
      globalAction[keyPath: action] = localAction
      callback(globalAction)
    }
  }
}
```

-  `run` 을 `sink` 로 바꾸어준다. 이 때, `sink` 는 `AnyCancellable` 을 반환한다.
  - 이러한 세부 사항을 관리할 Store가 보이지 않는 pure function reducer의 세계에 있기 때문에 어떻게 할 것인지조차 명확하지 않다.
  - 또한, `Effect` 를 callback closure로 생성하려고 하지만, 더이상 해당 인터페이스는 사용할 수 없다.
- 위의 코드가 실제로 무엇을하는지 생각해 보면, 단순히 **Local action을 생성할 수 있는 Local Effect를 Global Action을 생성 할 수 있는 Global Effect로 변환**하고자 하는 것이다. 이는 즉 `map` 과 동일하다.
- `Publisher.Map` 의 형식으로 감싸여진 구조를 `Effect` 로 바꾸어주기 위하여 convenience method 를 추가해주도록 한다.

```swift
extension Publisher where Failure == Never {
    
  public func eraseToEffect() -> Effect<Output> {
     Effect(publisher: self.eraseToAnyPublisher())
  }
    
}
```

### [Finishing the architecture refactor](https://www.pointfree.co/collections/composable-architecture/side-effects/ep81-the-combine-framework-and-effects-part-2#t957)

1. 이전까지는 closure-based initializer를 갖는 Effect 의 형태였지지만, 변경된 인터페이스에 대한 적용이 필요하다.

```swift
return [Effect { _ in // 🛑
  print("Action: \(action)")
  print("Value:")
  dump(newValue)
  print("---")
}] + effects
```

2. Publisher가 subscribe되어질 때 까지 실행되지 않길 바라므로 먼저 `Deferred` publisher로 감싸준다.

```swift
return [Deferred { _ in // 🛑
  print("Action: \(action)")
  print("Value:")
  dump(newValue)
  print("---")
}] + effects
```

3. `Deferred` 는 publisher의 반환을 필요로 하지만, 위의 효과는 **fire-and-forget effect** 이기 때문에 아무것도 하지 않고자 한다. 이를 위하여 combine에서 제공해주는 어떠한 vlaue도 emit하지않고 즉시 complete될 수 있는 `Empty` 를 제공한다.

```swift
eturn [Deferred { () -> Empty<Action, Never> in
  print("Action: \(action)")
  print("Value:")
  dump(newValue)
  print("---")
  return Empty(completeImmediately: true)
}.eraseToEffect()] + effects
```

- Fire-and-forget Effect는 추후에도 생성 가능성이 다분하기에 재사용성을 위하여 convenience method를 추가하도록 한다.

```swift
extension Effect {
  public static func fireAndForget(work: @escaping () -> Void) -> Effect {
    return Deferred { () -> Empty<Output, Never> in
      work()
      return Empty(completeImmediately: true)
    }
    .eraseToEffect()
  }
}
```

### [Refactoring synchronous effects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep81-the-combine-framework-and-effects-part-2#t1183)

#### PrimModal

- `PrimeModal` 모듈은 side effect가 존재하지 않기 때문에 빌드가 실패하지 않는다.

#### FavoritePrime

- `FavoritePrimes` 는 favorite prime을 save하고 load하는 Side Effect가 존재한다.
- `saveEffect` 의 경우, fire-and-forget effect이기에 사전에 정의해두었던 `Effect.fireAndForget`을 이용하여 처리하도록 한다.
- `loadEffect` 의 경우, synchronous effect로 result를 피드백해야할 필요가 있다.
  - Synchronus Effect의 helper를 추가하도록한다.
  - 먼저 Publisher가 subscribe되는 시점에 수행되도록 하기 위하여 `Deferred` 로 감싼다.
  - 작업에 대한 reulst를 보유하고 있는 publisher 반환하고자 하는데, combine에서 단일 value에 대한 emit을 할 수 있는 `Just`publisher를 제공해준다.

```swift
extension Effect {
  public static func sync(work: @escaping () -> Output?) -> Effect {
    return Deferred {
      Just(work())
    }
    .eraseToEffect()
  }
}
```

- Synchronous Effect를 적용 후 정상 빌드가 되며 수행도 되지만, save와 load effect를 수행하면 fatal error를 마주하게 된다.
  - `effectCancellbaleBag.remove(effectCancellable)` 을 수행하며 에러가 발생하게 된다.
    -  `receiveCompletion` closure가 `effectCancellable` 이 생성되는 시점보다 이전에 수행되어 발생하는 문제이다.
    - 즉시 완료하는 publisher의 경우 sink가 반환되기 전에 `receiveCompletion` closure가 호출된다.

```swift
func send(_ action: Action) {
    let effects = self.reducer(&self.value, action)
    effects.forEach {
        var effectCancellable: AnyCancellable!
        effectCancellable = $0.sink(
            receiveCompletion: { [weak self] _ in
                self?.effectCancellbaleBag.remove(effectCancellable)
            },
            receiveValue: self.send
        )
        self.effectCancellableBag.insert(effectCancellable)
    }
}
```

- 위의 에러를 해결하기 위하여 `effectCancellable` 이 Set에 제거되기 전과 삽입되기 전에 존재하는가에 대하여 확인해야하지만, publisher가 즉시 완료하면 Set에 삽입은 되겠지만, 삽입하기 전에 `receiveCompletion`이 이미 실행 되었기 때문에 제거할 기회가 없어진다.

  - 따라서, `receiveCompletion` 이 Set에 삽입되기 전에 호출되었는 가에 대하여 확인을 하여야한다.

```swift
var effectCancellable: AnyCancellable?
var didComplete = false
effectCancellable = effect.sink(
  receiveCompletion: { [weak self] _ in
    didComplete = true
    guard let effectCancellable = effectCancellable else { return }
    self?.effectCancellables.remove(effectCancellable)
  },
  receiveValue: self.send
)
if !didComplete, let effectCancellable = effectCancellable {
  effectCancellables.insert(effectCancellable)
}
```

### [Refactoring asynchronous effects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep81-the-combine-framework-and-effects-part-2#t1614)

```swift
URLSession.shared
				// Combine에서 제공하는 dataTaskPublisher를 이용하여
				// 네트워크 요청을 나타내는 publisher를 가져올 수 있다.
        .dataTaskPublisher(for: components.url(relativeTo: nil)!)
				// decode method에서 필요로하는 인자는 Data만이 해당하기에 map을 이용하여 data로 변경한다.
        .map { $0.0 }
				// Effect는 현재 `Never` failure를 갖기 때문에 간편하게 `replaceError`를 이용하여
				// 에러가 발생할 경우 대체 값을 반환하도록한다.
        .decode(type: WolframAlphaResult?.self, decoder: JSONDecoder())
        .replaceError(with: nil)
        .eraseToEffect()
```

