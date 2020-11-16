# Modular State Management: View State

### [Modularizing our views](https://www.pointfree.co/collections/composable-architecture/modularity/ep73-modular-state-management-view-state#t44)

- View들에 대하여 매우 단순화하였지만, 아직 modularizing은 하지 않았다.
- 현재의 **View들은 모두 app state에 접근할 수 있고, 모든 형태의 app action**을 보낼 수 있다.
  - 이것은 `AppState` 와 `AppAction` 에 대한  central `Store` 를 보유하고 있기 때문이다.
  - Store을 view에 전달할때마다 view에게 필요로 하는 것보다 많은 정보와 힘을 주고 있다.
  - View를 볼 수 있는 방법이 없으며, 어떠한 정보에 접근하는 지 알 수 없으며, 만들 수 있는 mutation을 알 수 없다.

```swift
@ObservedObject var store: Store<AppState, AppAction>
```

- View가 필요로 하는 state와 action에 대하여만 작동하는 store를 전달한다면, 이해가 쉬워지며, module로 추출이 가능해 진다..

### [Transforming a store's value](https://www.pointfree.co/collections/composable-architecture/modularity/ep73-modular-state-management-view-state#t246)

- 현재 Store의 value와 상호작용할 수 있는 방법은 property 를 통해 값을 받는 것이다.
- `value` 에 접근하려고 할 때마다 실제로 신경쓰는 app state의 일부만 얻을 수 있도록 store에서 자동적으로 변환하도록 적용해야한다.

```swift
func ___<LocalValue>(
    _ f: @escaping (Value) -> LocalValue
) -> Store<LocalValue, Action> {
    return Store<LocalValue, Action>(
        initialValue: f(self.value),
        reducer: { localValue, action in
            self.send(action)
            localValue = f(self.value)
        }
    )
}
```

### [A familiar-looking function](https://www.pointfree.co/collections/composable-architecture/modularity/ep73-modular-state-management-view-state#t563)

- 위의 함수는 아래와 같이 정리해볼 수 있으며, 이것은 `map` 과 매우 유사한 형태이다.

```swift
// ((Value) -> LocalValue) -> ((Store<Value, _>) -> Store<LocalValue, _>
// ((A) -> B) -> ((Store<A, _>) -> Store<B, _>)
// ((A) -> B) -> ((F<A>) -> F<B>)
```

- 원래 store와 새로운 store는 별개의 entity가 아니라 연결되어 있다. 파생된 store는 원래 store의 참조를 보유하고 작업을 보낼 때마다 변경한다.
  - Global Store에 알림을 보내서 local 변경 사항이 애플리케이션에서 전역적으로 표현 될 수 있도록 한다.
- Local Store는 Global Store의 `send(_: )` 를 직접 호출하기 때문에 Local 변경 사항을 Global store로 다시 전달한다.
- 하지만, Local Store는 Global Store로 부터의 업데이트를 받을 방법이 없다.
  - Local Stroe가 Root Store 의 업데이트를 observe한다면 가능하다.

### [What's in a name?](https://www.pointfree.co/collections/composable-architecture/modularity/ep73-modular-state-management-view-state#t857)

- `map` 함수는 매우 수학적인 컨셉이며, 고유 속성도 만족한다.
  -  `map`이 간단한 속성을 충족하면 `map`의 서명이있는 모든 가능한 함수 중에서 해당 유형의 `map` 을 고유하게 결정한다.
- 하지만, mapping 하는 것이 pure 구조일 경우에만 statement와 결과를 이해할 수 있다.
- 또한, `Store` 는 많은 동작들이 번들로 포함되어지는 class 타입이다.
  - Value Type과 같은 단순한 데이터로 정의되는 것이 아니라 시간이 지남에 따라 변경되는 변경 가능한 데이터를 보유하고 해당 데이터를 변경하는 데 도움이되는 메소드를 노출한다.
- 참조 유형에 대하여  `map`  이라고 불리는 것이 불편하다.
- 따라서, `map` 대신 domain 관점에서  `view` 라고 부른다.
  - Global Value의 local 버전만 볼 수 있다.

### [Propagating global changes locally](https://www.pointfree.co/collections/composable-architecture/modularity/ep73-modular-state-management-view-state#t1076)

- Global Store를 Local Store로 변환할 수 는 있지만, Local Store가 Global Store로 부터 파생된 변화를 받을 수 없다.
- `@Published` 는 `$` 를 이용하여 value update의 publihser를 제공한다.
  - Local Store를 만들 때 Global Store의 value publihser를 구독하고 이에 따라 이러한 업데이트를 전달하여 Global 업데이트를 알릴 수 있다.
- Local Store는 Local Store을 유지하는 cancellable 항목을 보유하고 있으며, 이는 memory leak 을 유발한다.

### [Focusing on view state](https://www.pointfree.co/collections/composable-architecture/modularity/ep73-modular-state-management-view-state#t1358)

- View가 필요한 것에 초점을 맞추기 위해 View가 작동하는 state를 변경 한 다음 해당 View에 전달한 Store이 이러한 값을 추출하기 위해 변형되었는지 확인했다.