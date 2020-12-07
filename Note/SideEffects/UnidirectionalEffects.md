# Side Effets: Unidirectional Effects

### [Synchronous effects that produce results](https://www.pointfree.co/collections/composable-architecture/side-effects/ep77-effectful-state-management-unidirectional-effects#t105)

- Save에 대한 side effect는 Store로 모두 이동하였지만, Load는 아직 view에 로직이 남아있다.
- Load Button에 대한 action을 추가하고, Store에 모든 로직을 옮긴다.
- 하지만, **effect의 결과를 가져 와서 reducer 바로 되돌리는 방법이 필요**로 하다.
- 즉, Effect closure에서  발생하는 작업은 effect를 완료하는 데 필요한 최소한의 작업만 수행하는 데 순수하게 관심이있을 수 있으며 작업 결과를 Action으로 wrapping하여 Reducer로 다시 보낼 수 있다.
- fire-and-forgot action을 위하여 Action을 optional로 반환한다.

```swift
typealias Effect<Action> = () -> Action?
```

```swift
// 최초의 effect만 수행하고 선택적인 action만 reducer로 피드백될 수 있다.
return { () -> Action? in
  for effect in effects {
    let action = effect()
    return action
  }
}

// 모든 effect가 동작하지만, 마지막 action만이 store에 제공된다.
return { () -> Action? in
  var finalAction: Action?
  for effect in effects {
    let action = effect()
    if let action = action {
      finalAction = action
    }
  }
  return finalAction
}
```

- 위의 Reducer 모두 최초 혹은 마지막의 action에 대해서만 동작하므로 수정이 필요로 하다.

### [Combining multiple effects that produce results](https://www.pointfree.co/collections/composable-architecture/side-effects/ep77-effectful-state-management-unidirectional-effects#t496)

- Reducer를 combine하면 일부 정보를 잃게되므로 더 이상 action의 단일 effect를 반환하는 것으로 충분하지 않다.

```swift
typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]
```

### [Pulling local effects back globally](https://www.pointfree.co/collections/composable-architecture/side-effects/ep77-effectful-state-management-unidirectional-effects#t615)

```swift
return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEffects = reducer(&globalValue[keyPath: value], localAction)
        // Local Effects를  Global Effects로 변환한다.
        return localEffects.map { localEffect in
            // GlobalEffect
            { () -> GlobalAction? in
	             // Local Effect로 부터 나온 LocalAction을
                guard let localAction = localEffect() else {
                    return nil
                }
                var globalAction = globalAction
	              // Global Action으로 변환한다.
                globalAction[keyPath: action] = localAction
                return globalAction
            }
        }
    }
```

- `pullback` 은 local state와 action에 대하여 작동하는 reducer를 global state와 action에 작동하는 Reducer로 바꾸는 방법이다.
  1. Global Reducer를 구성하여 global state와 action이 오면 KeyPath를 사용하여 local state와 action을 추출한다.
  2. Local reducer를 실행한다.
  3. 새로운 local state를 KeyPath를 사용하여 다시 Global state에 연결한다.
- Local reducer를 실행하면 로컬 action을 시스템으로 다시 보낼 수있는 효과인 Local effect 배열이 생성된다.
- Local effect를 실행하고, local action이 생성한 결과를 가져오고, Writable KeyPath를 이용하여 global action에 embed함으로써,  Local effect를 global effect로 변환 할 수 있다. 

### [Working with our new effects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep77-effectful-state-management-unidirectional-effects#t888)

- 기능이 추가됨에 따라 Reducer가 점점 커질 위험이 있다.
  - 이를 위하여 조그마한 private helper로 추출하도록 하자.

### [What’s unidirectional data flow?](https://www.pointfree.co/collections/composable-architecture/side-effects/ep77-effectful-state-management-unidirectional-effects#t1105)

- 데이터는 한 가지 방식으로만 변경된다.
  1. Reducer가 state를 변경할 수 있도록하는 작업이 reducer 들어온다. 
  2. 일부 side effect 작업을 통해 state를 변경하려면 reducer(변경의 능력을 가지고 있는)로 다시 피드백 할 수있는 새로운 action을 구성하는 것 외에는 선택의 여지가 없다.