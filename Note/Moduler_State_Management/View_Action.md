# Modular State Management: View Action

### [Transforming a store’s action](https://www.pointfree.co/collections/composable-architecture/modularity/ep74-modular-state-management-view-actions#t40)

- `Store`는 View State에 대해서는 개선을 하였지만, 여전히 `AppAction` 에는 의존하기 때문에, 완전히 분리된 모듈로 추출할 수 없다.
  - Action을 변화시켜야 한다.
- 현재 외부에서 action을 처리하고  `send(_:)` 를 이용하여  action을 store 에게 보내고 있다.
- Global action 대신 Local action을 해당 method로 보낼 수 있다면, Store의 어딘가에서 local action을 global action으로 wrapping하는 과정을 자동화할 수 있을 것이다.

```swift
func ___<LocalAction>(
    _ f: @escaping (LocalAction) -> Action
) -> Store<Value, LocalAction> {
    
    return Store<Value, LocalAction>(
        initialValue: self.value) { (value, localAction) in
        
        self.send(f(localAction))
        value = self.value
    }
}
```

- 값을 변경하는 것은 Store의 내부 동작에 따라 다르며, 그 값을 전혀 사용하지 않았더라도 변경 가능한 값을 다시 할당한다.
- 위의 형상은 이전에 나왔던 `pullback` 과 동일하다.

```swift
// ((LocalAction) -> Action) -> ((Store<_, Action>) -> Store<_, LocalAction>)
// ((B) -> A) -> ((Store<A, _>) -> Store<B, _>)
// ((B) -> A) -> (F<A>) -> F<B>)
// pullback: ((A) -> B) -> (F<B>) -> F<A>)
```

- Store에서 `map` 작업에 대해 설명한 것과 유사한 이유로 이 메서드를 `pullback`이라고 부르는 것이 불편하다.
  - Reference type에 대해 작동하고 pure하고 수학적 특성이 아닌이 객체의 동작에 의존하고 있다.

### [Combining view functions](https://www.pointfree.co/collections/composable-architecture/modularity/ep74-modular-state-management-view-actions#t395)

```swift
func view<LocalValue, LocalAction>(
    value toLocalValue: @escaping (Value) -> LocalValue,
    action toLocalAction: @escaping (LocalAction) -> Action
) -> Store<LocalValue, LocalAction> {
    
    let localStore = Store<LocalValue, LocalAction>(
        initialValue: toLocalValue(self.value),
        reducer: { localValue, localAction in
            self.send(toLocalAction(localAction))
            localValue = toLocalValue(self.value)
        }
    )
    self.cancellableBag.insert(
        self.$value.sink { [weak localStore] (newValue) in
            localStore?.value = toLocalValue(newValue)
        }
    )
    return localStore
}
```

### [Focusing on favorite primes actions](https://www.pointfree.co/collections/composable-architecture/modularity/ep74-modular-state-management-view-actions#t525)



### [Extracting our first modular view](https://www.pointfree.co/collections/composable-architecture/modularity/ep74-modular-state-management-view-actions#t687)

- `FavoritePriemsView` 를 완전히 다른 module로 추출한다.
- initilizer의 작성과 같은 약간의 보일러플레이트 코드가 존재한다.
- 이러한 모듈화는 더 많은 Global action과 state에 접근 할 수있는 매우 제한된 능력을 가지고 있다는 것을 보장하게 된다.

### [Focusing on prime modal actions](https://www.pointfree.co/collections/composable-architecture/modularity/ep74-modular-state-management-view-actions#t823)

