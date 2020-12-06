# Side Effets: Synchronous Effects

### [Adding some simple side effects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep76-effectful-state-management-synchronous-effects#t79)

- `nthPrime(_:, callback:)` 은  `Void` 를 반환하기 때문에 side effect를 발생시킬 것이다.
  - Caller 에게 중요한 거을 어느 것도 반환하지 않기 때문에 side effects을 수행할 수 밖에 없다.
  - 네트워크 요청은 유일한 Side Effects이지만, 복잡한 비동기식이다. 
  - 먼저, 더욱 간단한 것을 보아야한다.
- 현재 Favorite Primes는 메모리 상에만 저장되기 때문에 앱을 재시작할 경우 모든 정보가 날아가게 된다.
  - 버튼을 추가하여 Favorite Primes의 목록들을 디스크에 저장하고, 디스크로부터 state에 다시 로드하도록 한다.

### [Effects in reducers](https://www.pointfree.co/collections/composable-architecture/side-effects/ep76-effectful-state-management-synchronous-effects#t515)

- 현재의 코드는 우리의 Architecture 양식에 반하고 있다.
  -  UI의 action clousre는 최대한 logic-less여야한다.

### [Reducers as pure functions](https://www.pointfree.co/collections/composable-architecture/side-effects/ep76-effectful-state-management-synchronous-effects#t685)

- Reducers는 "pure" function으로 불리운다. 
  - 함수가 하는 모든 것은 함수의 signature에 담겨져 있다고 말한다.
  - 어떠한 state와 action을 input으로 취하며, 어떻게 state와 action을 바꿀 것인지 결정한다.
  - 제공되어진 데이터에 따라 결정된다.
- 반면 "impure" function은 
  - argument로 전달되지 않는 함수의 바깥 세상의 것에 대한 접근이 필요로 하거나 
  - 함수의 반환으로 설명되지 않은 것이 바깥 세상의 변화를 주는 것이다.
  - 즉, Side Effect는 함수의 숨겨진 입력 또는 출력에 지나지 않으며 함수가 암묵적으로 의존하거나 암묵적으로 변화한다는 의미이다.

### [Effects as values](https://www.pointfree.co/collections/composable-architecture/side-effects/ep76-effectful-state-management-synchronous-effects#t961)

- 단순히 Void를 반환하는 대신 부작용에 대한 설명을 반환할 수 있다.

- Button의 body에서 본래 side effect를 수행하였다.

  - `Button.init(<#title: StringProtocol#>, action: <#() -> Void#>)`

  - `action`  은 void-to-void closure로, 코드에서 side effect를 어떻게 묘사하는 가에 대한 정의만큼 좋다.

```swift
public typealias Effect = () -> Void
public typealias Reducer<Value, Action> = (inout Value, Action) -> Effect
```

### [Updating our architecture for effects](https://www.pointfree.co/collections/composable-architecture/side-effects/ep76-effectful-state-management-synchronous-effects#t1034)



### [Reflecting on our first effect](https://www.pointfree.co/collections/composable-architecture/side-effects/ep76-effectful-state-management-synchronous-effects#t1424)

- View에 side effect이 있었는데, 제어 할 방법이 필요하다는 것을 깨달았다.
  - View 를 단순화하는 유용한 방법은 **모든 로직을 Reducer로 이동**하고 **View가 User action을 Store로 보내는 책임**을지게 하는 것임을 발견하였다.
- Reducer가 void-to-void closure를 반환하므로써 작업을 실제로 실행하지 않고 **side effect을 유지할 수 있으며 작업의 실행 책임을 store에 넘긴다.**