# Adaptive State Management: State

- View 내부에서 UI를 표시하는 데 필요한 모든 state뿐만 아니라, 나중에 표시되지 않을 수도 있는 자식의 모든 상태를 보유하는 단일 store로 인한 잠재적인 문제가 존재한다.
  - View들이 view가 신경쓰는 state에만 접근할 수 있는 다른 객체들을 보유할 필요가 있다.
  - 실제로 관심을 갖는 state의 변경 사항에 대해서만 알림을 받을 수 있는 더 좋은 기회가 있다.
    - 변경에 대하여 성공한다면 Store는 전혀 `ObservableObject`일 필요는 없고 이 Secondary object만 관찰 할 수 있어야한다.

### [View models and view stores](https://www.pointfree.co/collections/composable-architecture/adaptation/ep95-adaptive-state-management-state#t118)

- State 변경에 대한 알림을 중지하도록 `Store` 에서 `ObservableObject`  채택을 제거한다.
  -  View는 UI를 렌더링할 때 `value` 를 사용하지 않아야 하므로, `value` 에 대한 `public` 접근을 제거한다.
  - **파생된 모든 하위 store들의 `value` 에 대한 변경사항을 다시 재생하고 value의 publihser가 있으면 이 작업을 매우 쉽게 수행할 수 있기 때문에 `value` 를 `@Published` 로 유지**하도록 한다.

```swift
public final class Store<Value, Action> /* : ObservableObject */ {
  …
  @Publisher
  /*public*/ private var value: Value
```

- Secondary Object를 구현하는 방법을 알아보도록 한다.

  - State의 변경사항에 대한 알림을 실제로 담당하게 되는 객체이다.
  - **"View Model"** 용어는 view를 정확하게 설명하는 도메인을 묘사하는 방법으로 오랫동안 사용되어 왔다.
    - 이것은 **비지니스 로직과 view 사이에 추상화를 제공**한다.
    - **비지니스 로직은** API 요청의 loading state와 같이 **UI에 직접 맵핑되지 않는 개념**을 갖을 수 있다.
    - 반면 **View에는** 버튼의 활성화 또는 비활성화 상태와 같이 **사용자가 볼 수 있는 매우 구체적인 내용**이 있다.
  - "View Model" 로 부터 영감을 받아 `ViewStore` 를 추가한다.

#### ViewStore

- **Store가 앱의 모든 복잡한 비지니스 로직을 모두 보유**하고 있어 **view가 신경쓰는 것보다 더 많은 정보를 포함**할 수 있다.
  -  `ViewStore` 는 **view가 관심을 갖는 도메인만 보유**한다.
  - 해당 정보가 필요하지 않은 경우, 하위 view의 도메인을 보유 할 필요조차 없다.
- 이 객체가 **SwiftUI와 상호 작용하여 뷰의 재렌더링을 트리거**할 수 있기를 원하므로 클래스가 되어야한다.
  - 또한, SwiftUI가 알림에 연결할 수 있어야하기 때문에 `ObservableObject` 여야 한다.
  - 관찰 가능한 객체가 되려면 store의 값이 변경될 때마다 발행하는 publisher를 보유해야 한다.
  - SwiftUI는 이 클래스 내의 `value`에 대한 storage를 동시에 선언하고, `value` 가 변경될 때 자동으로 해당 publihser 핑하는 쉬운 방법을 제공한다.
- `ViewStore` 의 기본은 단순히 **value를 wrapping하고 관찰가능한 객체로 노출**한다.
- Value와 action의 부분적인 도메인을 알고 있는 store가 있는 경우, **외부의 state 변경에 대한 알림을 방지**하는  `ViewStore` 를 파생할 수 있다.
- 이미 `Store`에 `view` 메서드가 있으며, 이는 부모 view에서 자식 view로 포커스가 있는 store를 전달하는 데 사용된 메서드이다. 
  - `ViewStore`의 개념을 고려하기 전에이 메서드의 이름을 지정했으므로 두 이름을 동시에 사용하는 것이 약간 혼란스러워 보인다.
  - `ViewStore` 변환을 위하여 해당 이름을 확보할 수 있도록 원래의 `view` 메서드의 이름을 `scope`로 변경한다.
- `ViewStore` 의 value 업데이트를 위하여 store의 value의 모든 변경 사항을 구독하고, 이를 `ViewStore`에서 재생하도록 한다.

### [View store performance](https://www.pointfree.co/collections/composable-architecture/adaptation/ep95-adaptive-state-management-state#t605)

- 현재로서는 Global store가 변경 될 때마다 연관된 모든 ViewStore도 변경되므로 view에 대한 재계산이 트리거된다.
  - 이를 방지하기 위하여 `removeDuplicates` 메서드를 이용하도록 한다.
  - Equatable이 불가능한 Value를 위하여 predicate를 제공한다.
  - Cancellable은 이 closure에서 viewStore를 유지하고 있지만, viewStore 자체도 cancellable을 속성으로 유지하고 있기 때문에 순환 참조가 발생할 수 있다.

```swift
public func view(
    removeDuplicates predicate: @escaping (Value, Value) -> Bool
) -> ViewStore<Value> {
    let viewStore = ViewStore(initialValue: self.value)
    viewStore.cancellable = self.$value
        .removeDuplicates(by: predicate)
        .sink { [weak viewStore] newValue in viewStore?.value = newValue }
    return viewStore
}
```

### [Counter view performance](https://www.pointfree.co/collections/composable-architecture/adaptation/ep95-adaptive-state-management-state#t1121)

### [View store memory management](https://www.pointfree.co/collections/composable-architecture/adaptation/ep95-adaptive-state-management-state#t1421)

- 증가 버튼을 클릭해도 UI가 전혀 변경되지는 않지만, 로그에서 비즈니스 로직이 실행 중이고 앱 상태가 변경되고 있음을 확실히 알 수 있다. 
  - Reducer에 로깅을 추가하면 작업이 확실히 store에 전달되고 state가 업데이트 되지만 변경사항이 UI에 반영되지 않음을 알 수 있다.
  - ViewStore는 관찰 가능한 것이기 때문에 UI의 렌더링을 제어하는 것은 ViewStore이다. 
    - ViewStore의 구성을 변경하여 먼저 store의 범위를 지정한 다음 그것을 볼 수 있도록 하였다.
    - `scope` 를 호출할 때 중간 store를 만들지만, 실제로 중간 store를 유지하는 것이 없으므로 즉시 할당이 해제되므로 ViewStoredp 변경 사항이 통지되지 않는다.
    - 동일한 store에서 `scope` 변환을 여러 번 호출하면 서로를 유지하는 store chain을 얻게 된다.

```swift
let localStore = Store<LocalValue, LocalAction>(
  initialValue: toLocalValue(self.value),
  reducer: { localValue, localAction, _ in
    self.send(toGlobalAction(localAction))
    localValue = toLocalValue(self.value)
    return []
},
  environment: self.environment
)
```

- 파생된 store를 유지하려면 파생된 view store가 필요하다.
  - `sink` clousre 내에서 `self` 를 참조함으로써 view store를 유지할 수 있다.

```swift
viewStore.cancellable = self.$value
  .removeDuplicates(by: predicate)
  .sink { newValue in
    viewStore.value = newValue
    self
}
```

### [Adapting view stores](https://www.pointfree.co/collections/composable-architecture/adaptation/ep95-adaptive-state-management-state#t1671)

- ViewStore는 view에 있는 **일부 논리를 움직일 수있는 완벽한 장소를 제공**한다. 
  - 더 좋은 점은 **불필요한 재렌더링을 건너 뛸 수 있는 더 많은 기회를 제공**한다.

```swift
if self.viewStore.value.favoritePrimes.contains(self.viewStore.value.count) {

if self.viewStore.value.isFavorite {
```

- 가질 수있는 완벽하게 좋은 상태이지만, 일부는 애플리케이션의 추상적인 표현 (특히 `count` 및 `favoritePrimes` 필드)의 핵심인 state와 일부 state가 혼합되어 있다는 것이 조금 이상하다고 생각할 수 있다. 
  - 화면에 표시되는 내용을 더 자세히 설명한다. 
  - e.g. `alertNthPrime`, `isNthPrimeButtonDisabled` 및 `isPrimeModalShown`

```swift
public struct CounterFeatureState: Equatable {
  public var alertNthPrime: PrimeAlert?
  public var count: Int
  public var favoritePrimes: [Int]
  public var isNthPrimeButtonDisabled: Bool
  public var isPrimeModalShown: Bool
}
```

- 원한다면 ViewStore의 개념을 사용하여 이 두 가지 상태를 더 잘 분리 할 수 있다. 
  - `isNthPrimeButtonDisabled` 상태 부분에 대해 이 작업을 수행하여 어떻게 진행되는지 확인할 수 있다. 
  - 이 필드는 UI에서 나타내는 내용을 따라 매우 명확하게 이름이 지정되며, view 코드가 가능한 가장 간단한 방법으로 사용한다는 것을 의미하기 때문에 정말 편리하다.
  - 이 필드의 값은 "nth prime"에 대한 API 요청이 진행 중인지 여부를 기반으로 하며, 해당 정보를 로드하려고 할 때 버튼을 비활성화하고 응답을받는 즉시 다시 활성화한다.