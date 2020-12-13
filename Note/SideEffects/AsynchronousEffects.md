# Side Effets: Asynchronous Effects

### [Introduction](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t5)

- Disk Effct에서 Loading을 추출하고 어떻게든 redcuer에 모델링하고자 하였다.
  - 이 effect가 이전에 다루었던 것들과는 다름을 알 수 있었다.
  - Save effect는 필수적으로 'fire-and-foget'이였고, 그저 수행하고 어떠한 것도 어느 누군가에게 알릴 필요가 없었다.
- 하지만, loading effect는 load되어진 data를 reducer로 다시 집어넣을 방법이 필요로 하였다.
  - 이것을 우리를 effecting signature를 `void-to-void closure` 에서 `void-to-optional action` closure로 refactoring하도록 이끌었다.
  - 이것은 effect를 job을 수행하는데 필요로하는 최소한의 work만 수행할수 있고, 또다른 action을 보내어 result를 다시 reducer로 공급하도록 한다.
    1. 먼저 reducer를 실행하고
    2. 실행하고자 하는 모든 efffect를 모으고
    3. effect를 실행하기 위하여 오류를 반복하고,
    4. 생성되어진 모든 action을 store에 다시 보냄으로써
    5. effect의 통역자가 된다.
- Unidirectional Data Flow
  - **Data는 오로지 하나의 방법으로만 변경**될 수 있다.
    - Recure가 state를 변경할 수 있는 action이 reducer로 들어간다.
    - 어떠한 Side effect 작업을 통하여 state를 변경하고자 한다면, reducer에게 다시 공급할 수 있는 새로운 action을 구성하지 않고서는 방법이 없다.
- 이러한 종류의 data flow는 오로지 하나의 위치에서만 state가 변경되는 것을 볼 수 있기 때문에 매우 이해하기 쉽다.
- 하지만, 이것은 또한 effect result를 다시 store에 공급하기 위한 action을 추가해야하는 비용이 발생한다.
  - 이것이 UI Framework이 사용을 단순화하기 위해 엄격한 Unidireictionayl Style을 회피하는 방법(e.g. Two-way binding)을 제공하는 이유이다.
    - 하지만, 이는 UI를 통해 데이터가 흐르는 방식을 복잡하게 만드는 대가가 될 수 있다.

### [Extracting our asynchronous effect](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t137)

- 즉각적으로 optional action을 반환할 수 있는 effect가 필요로 하기 때문에 현재는 오로지 syncrhonous effect만을 지원한다. 
  - 이것은 시간이 걸리는 작업을 수행하고 action을 나중에 반환할 수 있는 능력이 없다.
  - 만약 effect가 작업을 수행하는 데 시간이 필요로 한다면, 나머지 effect가 돌아가는 것을 차단하고, 새로운 event가 store로 가는 것을 차단할 것이다.

```swift
func nthPrimeButtonAction() {
  self.isNthPrimeButtonDisabled = true
  nthPrime(self.store.value.count) { prime in
    self.alertNthPrime = prime.map(PrimeAlert.init(prime:))
    self.isNthPrimeButtonDisabled = false
  }
}
```

- 관련된 Local state에는 요청이 진행 중일 때 버튼을 비활성화하고 요청이 성공하면 결과와 함께 경고를 표시하는 것이 된다.
- 이 작업을 inline으로 수행하는 대신, effect를 reducer에서 캡쳐할 수 있도록 store에 action을 보내길 원한다.

### [Local state to global state](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t385)

- `isNthPrimeButtonDisable` 와 `alertNthPrime` 등을 위하여 counterReducer에 추가적인 state를 알 수 있도록 해야한다.

- `nthPrimeButtonTapped` 의 결과를 다시 reducer에 공급하기 위하여 `nthPrimeResponse` 라는 action을 추가하도록 한다.

- `nthPrime(_:)` 는 asynchronous하지만, 현재의 reducer의 effect는 synchronous하여야 한다.

  - Semaphore 를 이용하여 synchronous하도록 수정한다.

- 새로 추가된 상태들을 위하여 CounterViewState를 수정하도록한다.

```swift
public typealias CounterViewState = (
  alertNthPrime: PrimeAlert?,
  count: Int,
  favoritePrimes: [Int],
  isNthPrimeButtonDisabled: Bool
)
```

- counterReducer와 primeModalReducer가 필요로 하는 필드를 뽑아내는 single key path를 제공하지 않기 때문에 작동하지 않을 것이다.
  - 이러한 key path에 접근하려면 일부 computed property를 정의해야한다.
  - 즉, `typealias`가 아닌 `struct` 로 변경해야한다.

### [The async signature](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t959)

- Async를 sync로 바꾸는 effect를 구현하는 것은 좋은 해결책이 아니다.

  - 이 Effect는 차단이 되어 완료가 될 때까지 다른 effect를 실행할 수 없게 된다.

- Async를 지원하기 위하여 effect가 수행되는 store의 `send(_:)` 를 수정한다.
```swift
DispatchQueue.global().async {
  effects.forEach { effect in
    if let action = effect() {
      DispatchQueue.main.async {
        self.send(action)
      }
    }
  }
}
```

- 상기의 코드는 몇가지 문제점이 존재한다.
  - Effect가 수행되는 queue를 직접적으로 `global` 임을 지정해놓았다.
    - Store의 사용자들에게 유연한 선택을 못하게 한다. 
    - 이상적으로, 각각의 effect가 원하는 비동기 방법을 결정하도록 하는 것이 좋다.
  - Asynchronous effect는 내부적으로 GCD Semaphore를 이용하여 asynchrony를 관리한다.
    - wait하고 signal을 보내야하는 semaphore를 만드는 대신, effect를 재모델링할 수 있다면 더 좋을 것이다.

```swift
struct Parallel<A> {
  let run: (@escaping (A) -> Void) -> Void
}
```

- 이 **signature는 우리가 호출하는 함수에 제어권을 넘겨 주어 즉시 값을 요구하지 않고 준비가되었을 때 값을 돌려 줄 수 있도록**한다.
- 선택적 작업을 즉시 반환해야하는 이 syncrhonous effect signuatre를 버리고 대신 준비가 되었을 때 작업을 제공 할 수있는 asyncrhonous signature을 사용해야합니다.

### [The async effect](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t1315)

#### send

- callback을 제공하여 각각의 effect를 수행한다.
- 그리고 callback이 호출되었을 때, resulting action을  `send(_:)` 로 전달한다.

```swift
public func send(_ action: Action) {
  let effects = self.reducer(&self.value, action)
  effects.forEach { effect in
    effect { action in self.send(action) }
  }
}
```

#### pullback

- Effect를 실행하여 local effect를 global effect로 변환한 다음 callback을 사용하여 local effect를 global effect에 포함해야 한다.

```swift
public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
  _ reducer: @escaping (inout LocalValue, LocalAction) -> [Effect<LocalAction>],
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>
) -> (inout GlobalValue, GlobalAction) -> [Effect<GlobalAction>] {
  return { globalValue, globalAction in
    guard let localAction = globalAction[keyPath: action] else { return [] }
    let localEffects = reducer(&globalValue[keyPath: value], localAction)
    return localEffects.map { localEffect in
      { callback in
//        guard let localAction = localEffect() else { return nil }
        localEffect { localAction in
          var globalAction = globalAction
          globalAction[keyPath: action] = localAction
          callback(globalAction)
        }
      }
    }
  }
}
```

#### logging

- store에 다시 공급해야할 정보가 없으므로 callback을 무시한다.

```swift
public func logging<Value, Action>(
  _ reducer: @escaping (inout Value, Action) -> [Effect<Action>]
) -> (inout Value, Action) -> [Effect<Action>] {
  return { value, action in
    let effects = reducer(&value, action)
    let newValue = value
    return [{ _ in
      print("Action: \(action)")
      print("Value:")
      dump(newValue)
      print("---")
    }] + effects
  }
}
```

### [Refactor-related bugs](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t1544)

- nth prime button 을 눌르면, 응답을 받는 데 시간이 많이 걸리는 것으로 보인다.
- 또한, alert 가 뜨기 훨씬 이전에 log가 찍히는 것을 볼 수 있다.
- 이 asynchronous effect를 reducer로 옮기고 action을 store에 전달함으로써 이전에 SwiftUI가 처리하던 문제를 도입하였다.
- 문제는 **Background thread에서 store 값을 변경**한다는 것이다. 
  - 즉, Background thread에서 action을 다시 store로 보낸다.
  - 즉, store의 값이 Background thread에서 변경되어 Bakcground thread에서 SwiftUI에 값이 게시되고 있음을 의미한다.
- 위의 문제는 해결이 되었지만, 버튼을 두 번 누르면 경고가 표시되지 않는다.  때때로 crash가 발생할 때도 있다.

### [Thinking unidirectionally](https://www.pointfree.co/collections/composable-architecture/side-effects/ep78-effectful-state-management-asynchronous-effects#t1726)

- 일반적으로 binding을 사용하여 특정 종류의 presentation에 대해 SwiftUI를 통하여 제어를 처리하므로, SwiftUI가 일부 상태를 `nil` 로 만들 수 있다.
- 하지만, `Binding.constant` 를 이용하였고 이것은 alert가 사라질 때  `nil` 이 되는 것을 방지할 수 있다.
- Alert가 사라질 때 `alertNthPrime`을 nil로 만드는 effect를 추가한다. 하지만 이것은 더욱 복잡한 상황을 만든다.
  - 이전에 acrhictecure에서 고려하지 않았떤 alert의 표시 및 해제에 대한 아이디어와 함께 결합되어 있다.
    - 이 문제를 해결하려면 alert의 표시와 관련된 local state를 추출하는 것이 의미하는 것, Binding의 관리방법 그리고 해제 등에 대하여 고려해야했다.
  - 이 effect는 async이다.
    - Sync보다 본질적으로 더욱 복잡하다.
    - Threading 문제를 고려해야했지만, 이는 Architecture의 결함이 아니다.
    - View에서 ObservableObject로 로직을 추출하는 모든 사람이 격면하게 될 문제이다.