# Higher-Order Reducers

- **Higher-order function** : 함수를 입력으로 사용하고 함수를 출력으로 반환하는 함수

### [What’s a higher-order reducer?](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep71-composable-state-management-higher-order-reducers#t116)

#### Higher-order Redcuer
- Reducer를 입력으로 사용하고 Reducer를 출력으로 반환하는 Reducer
- e.g. `pullback`, `combine`

```swift
func higherOrderReducer(
  _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {

    return { state, action in
        // do some computations with state and action
        reducer(&state, action)
        // inspect what happened to state?
    }
}

```

- 매우 밀접하게 연관되어져 있는 로직이지만 동떨어진 Reducer들에 속해있다.
  - 이러한 것은 다른 모듈 혹은 파일에서도 발생한다면, 변경을 따라가기 어려워 진다.
  - Reducer의 모든 action들을 감사하고 새 이벤트를 추가하기 위한 올바른 지점에 연결되어 있는지 확인해야한다.

### [Higher-order activity feeds](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep71-composable-state-management-higher-order-reducers#t392)

- Higher-order Reducer는 High Level에서 들어오는 **action들을 검사 할 수 있는 기능을 제공**하기 때문에 **activity tracking logic을 한 곳에 집중**시킬 수 있다.
- Higher-order Reducer인 ` activityFeed` 에 기존의 `appReducer` 를 공급하면, store 에서 사용할 reducer가 된다.
- 세분화된 reducer는 큰 state에 대해 알아야할 필요가 없어진다.

### [Higher-order logging](https://www.pointfree.co/collections/composable-architecture/reducers-and-stores/ep71-composable-state-management-higher-order-reducers#t745)

- ActivityFeed에 대한 higher-order reducer를 구성하였지만, state mutation이 이전과 동일한지 확인하기 위한 스크린이 존재하지 않는다.
- Logger를 구축하여 위의 문제를 해결하도록 하자.
- `Store`의 `send(_:)` 에서 직접적으로 log를 남길 수 있지만, 원치않는 이들에게 까지 logging이 강제화된다.
- Higher-order reducer를 이용하여 log 기능을 구현하자.
- `bar(foo(logger(activityFeed(appReducer))))` 이와 같이 composition nesting이 지저분해지는 단점이 존재한다.