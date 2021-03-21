# Adaptive State Management: Performance

### [Fixing a couple memory leaks](https://www.pointfree.co/collections/composable-architecture/adaptation/ep94-adaptive-state-management-performance#t126)

- 현재의 코드에는 두 가지의 Memory leak이 존재한다.
  - Memory Graph Debugger은 코드에 있는 Retain cycle을 찾는데 유용하다.
- `sink` 에서 retain cycle이 발생하는 것을 확인할 수 있다.
  - `sink` 메소드는 `effectCancellable` 을 캡쳐하지만, `effectCancellable` 을 정의하기 위하여 `sink` 의 output을 이용하고 있다.

```swift
effectCancellable = effect.sink(
  receiveCompletion: { [weak self, weak effectCancellable] _ in
    didComplete = true
    guard let effectCancellable = effectCancellable else { return }
    self?.effectCancellables.remove(effectCancellable)
}
```

- `sink` 메소드의 `receiveValueReceive` clousre에서 `self.send` 를 직접 전달하고 있다.
  - 그는 `sink`가 자기 자신을 소유하고 있기 때문에 기술적으로는 retain cycle이지만,  또한  `sink`가 `sink` 로부터 반환되는 cancellable을 소유한다.
  - 이러한 effect를 실행하는 store은 다른 모든 store가 파생되는 뿌리이다.
  - State 및 action의 하위 집합만 노출하는 store에 기존 store를 집중시킬 수있는 `view` 메소드가 있으며, 이러한 작은 store를 사용하여 view에 전달한다.
  - **모든 파생된 store는 실제로 내부적으로 root store만 호출**하는 반면, 실제로 모든 것을 구동하는 **root store는 응용 프로그램의 최상위 수준인 `SceneDelegate`에서 한 번만 생성**된다.
  - 따라서 이러한 잠재적 Memory leak은 root store를 처음부터 다시 여러 번 재생성하려고 할 때에만 발생할 수 있지만, 이 작업을 수행하려고 하는 사람이 있을 수 잇으므로 수정이 필요로 하다.

```swift
receiveValue: self.send

receiveValue: { [weak self] in self?.send($0) }
```

### [View.init/body: tracking](https://www.pointfree.co/collections/composable-architecture/adaptation/ep94-adaptive-state-management-performance#t551)

- 현재의 아키텍쳐에는 잠재적인 성능 문제가 존재한다.
- `Store` 는 `ObservableObject` 를 준수하고 있으며, `value ` 라고 불리우는 `@Published` 필드를 가지고 있다.
  - `value` 이 변경될 때마다, 연관된 것들에게 변경사항이 통보된다.
- 만일 연관된 것이 SwiftUI의 view와 관련된 것이라고 가정해볼 때, 각각의 view들은 store의 변경사항을 view의 렌더링에 연결하기 위하여, `@ObservedObject`  라는 propertyWrapper를 이용하여 store를 소유할 것이다.

```swift
struct ContentView: View {
  @ObservedObject var store: Store<AppState, AppAction>
  …
}
```

- `init` 과 `body` 에 확인을 위하여 `print` 를 추가해보면, **앱의 변경사항이 있을 때마다 `body` 영역이 호출**되는 것을 볼 수 있다.
  - `ContentView`는 view를 렌더링하기 위해 store의 어떠한 데이터도 사용하지 않는다. 그저 일부 navigation link의 정적 목록 일뿐이다.	
  - 또한 이 화면에서 수행하는 모든 작업은 `body` 속성을 트리거하는 것처럼 보인다. 
  - `ContentView` 는 전체적인 application state의 store(`Store<AppState, AppAction>`)를 소유하고 있고, 그로인하여 앱의 일부가 변경되면 view가 자체적으로 다시 계산된다.
- 다행히도, **UI가 과도하게 렌더링되는 것을 방지하기 위해 내부적으로 강력한 비교 작업을 수행하고 있으며 이러한 view의 구성은 매우 가볍기 때문에 너무 많은 부담을 주지 않는다.**

- 모든 view들의 `init`, `body` 에 `print` 를 추가하여 구동하여 보면, 아래와 같은 로그가 나온다.
  - 이 때, `CounterView.init`, `FavoritePrimesView.init` 이 구동되는 것은 알 수 있지만, 각각의 `body` 가 불리우지 않는 것을 확인할 수 있다.
  - 이렇게 작은 view 구조체를 만드는 것은 매우 가볍고 필요할 때만 `body`가 호출되기 때문에 두려워하지않아도 된다.

```swift
ContentView.init
ContentView.body
CounterView.init
FavoritePrimesView.init
```

- CounterView에서 카운트를 증가시키면, 아래와 같은 로그를 볼 수 있다.
  - `CounterView` 가 재계산될 뿐만 아니라, `ContentView` 또한 재계산 되었다. 
  - 이로 인해 `CounterView`가 다시 계산되었지만 `ContentView`도 다시 계산되었으며, 이로 인하여 새로운 `CounterView` 및 `FavoritePrimesView`를 만든 다음 `CounterView`를 다시 계산하였다.
  - 이것은 이상하지만 다시 말하지만 root인 `ContentView`는 모든 `AppState`의 observed store를 보유하고 있어, state가 변경 될 때 이러한 것을 발생하기 때문에 이를 예상할 수 있다.

```swift
CounterView.body
ContentView.body
CounterView.init
FavoritePrimesView.init
CounterView.body
```

### [View.init/body: analysis](https://www.pointfree.co/collections/composable-architecture/adaptation/ep94-adaptive-state-management-performance#t896)

- 전체 View Hierarchy가 roto에서 modal까지 다시 생성되고 때로는 view가 여러 번 생성되기도 한다.
  - 우리는 선호하는 소수 배열에 단일 숫자를 추가하고 있으며, `CounterView` 및` ContentView`는 해당 배열에 대해 신경 쓰지 않는다. 
    - UI를 표시하기 위해 전혀 사용하지 않는다. 
    - 더 나쁜 것은 이 View Hierarchy가 깊을수록이 문제가 악화될 것이다.

- `CounterViewState`에 대한 store 만 필요하다고 말하더라도 `CounterViewState`뿐만 아니라 앱 state의 모든 부분에 대한 변경 사항을 view에 알린다. 
  - 이는 view에 전달된 store가 모든 `AppState`와 함께 작동하는 root, global store에서 파생 되었기 때문이다.
- Global store를 Local store로 전환하는 변환 방법 인 `view` 메소드의 구현을 살펴보면 확인할 수 있다.
  - Local value의 변경이 없음에도 불구하고, **Global store의 값의 변화가 발생할 때 즉각적으로 local store로 즉시 재생**한다.

```swift
localStore.viewCancellable = self.$value.sink { [weak localStore] newValue in
  localStore?.value = toLocalValue(newValue)
}
```

- 우리가 시도해볼 수 있는 방법은, 어떻게든 stream에서 중복되는 것을 제거하는 것이다.
  - 하지만, view가 현재 보여주고 있는 것보다 더욱 많은 state를 나타내는 store를 유지하는 문제로 인하여, 이는 큰 도움이 되지 않는다.

```swift
localStore.viewCancellable = self.$value
  .map(toLocalValue)
  .removeDuplicates()
  .sink { [weak localStore] newValue in localStore?.value = newValue }
```

### [View.init/body: stress test](https://www.pointfree.co/collections/composable-architecture/adaptation/ep94-adaptive-state-management-performance#t1064)

- Composable Architecture의 주요 이점 중 하나는 통합되고 구성된 reducer와 store가 있어 앱 state를 변경하는 단일의 일관된 방법을 확보하고, 이러한 변경이 앱 전체에 공유될 수 있다는 것이다. 

  - 하지만, 이는 필요 이상으로 view의 방식을 재계산하도록 하여 이상한 동작을 제공하였다.

    Apple은 매우 가벼운 작업이라고 하였지만, 모든 곳에서 view를 재계산하는 경우 충분히 큰 앱은 성능 문제에 부딪 힐 수 있다. (e.g. `ForEach`)

  - Store의 디자인 선택으로 인해 SwiftUI에서 성능 문제가 발생할 수 있지만 실제 애플리케이션에서 이것이 얼마나 큰 문제인지는 확실하지 않다.

