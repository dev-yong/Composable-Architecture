## Reducer

### Introduction

- Application Architecture의 문제를 탐색하였고, 복잡하게 만드는 근원을 밝히려고 노력하였다.
    - State의 일부분에 대한 mutation이 모든 screen에 즉시 반영 되도록, 여러 screen에서 **공유하여 사용할 수 있는 복잡한 app state**를 원한다.
    - **일관성 있는 방법으로 state가 변경**되어, 코드를 처음 접하는 사람도 Application을 통과하는 Data flow가 어떻게 흐르는지 명확히 알 수 있길 원한다.
    - **Simple, Composable unit으로 크고 복잡한 application을 만들** 수 있길 원한다.
        - 가능하다면 자체 module에서도, Component들이 완전히 분리하여 build할 수 있고, 후에는 Component들이 다른 큰 application에 연결할 수 있는 것을 원한다.
    - **Side Effect를 수행하고 그 결과를 application에 다시 제공**하기 위하여 잘 정의된 **mechanism**이 필요하다.
    - **테스트가 가능한 Architecture**를 원한다.
        - 적은 setup으로 유저가 앱에서 행한 일련의 행동을 묘사할 수 있는 테스트를 작성할 수 있어야 하고
        - 그 행동들이 수행 되어진 후의 앱의 state에 대하여 확고히 할 수 있어야 한다.
- 몇 가지의 문제들이 존재한다.
    - 데이터가 Application에 어떻게 공급 되는지 모호하게 **mutation이 view들에 흩어져 있다**.
    - 전체 App state를 가질 필요가 없도록 view를 작게 쪼개기를 원한다.
        - 이러한 view는 **app state의 일부분만을 필요**로 할 것이며, 간단한 방법으로 달성할 수 있어야 한다.
    - mutation이 SwiftUI view에 묶여 있기 때문에 **테스트할 좋은 방법이 없다.**

### A better way to model global state

- 몇 가지 API 의 변화가 존재한다.
    - `BindableObject` → `ObservableObject`
    - `objectWillChange`
    - `@Published`
- 개선이 되었지만 아직도 개선이 필요로 하다.
    - **Model Layer가 Combine 프레임워크에 매우 밀접하게 결합**되어있다.
        - 모든 property는 Combine Publisher로 wrapping되어진다.
        - `AppState` 를 value semantics으로 변경하고 매우 얇은 `ObservableObject` wrapper (`Store`)를 만들어라.
    - 이전 보단 나아졌지만, 아직도 `@Published`로 모든 property를 감싸야 한다.
    - `@Published` 로 감싸지 않을 경우 SwiftUI는 이것의 변화를 알리지 않을 것이다.
    - `ObservableObject` 는 여전히 Value Type이 아닌 class만 적용이 가능하다.
        - Value Type은 세분화된 제어를 제공하고  mutability를 보장하기에 state를 위한 훌륭한 컨테이너이다.

### Functional state management

- 일관적인 방법으로 mutation을 수행하도록 하자.
    - State mutation 은 현재 상태와 발생한 이벤트를 취하고 이러한 정보를 모두 사용하여 **완전히 새로운 state 도출하는 행위**입니다.
    - **함수처럼** (Pure Function)
- User Action에 대한 정의가 잘못 되어있다.
    - SwiftUI에서 "User Action"는 단지 action closure가 수행됨을 의미한다.
    - 이러한 컨셉을 적절한 데이터 타입으로 변경하고 작동할 수 있도록 해야 한다.

### Ergonomics: capturing reducer in store

- 매번 reducer를 직접 호출하고 store의 state에 재할당하는 것은  boilerplate이다.
    - 이것을 store로 옮긴다면 깔끔해 질 것이다.
- `Store`의 `value` property의 setter를 private으로 변경한다면 `Reducer` 를 거치지 않는 한 app의 state는 변경할 수 없게 된다.

### Ergonomics: in-out reducers

- 현재 정의된 reducer 는 두 가지의 성가신 점이 존재한다.
    - State를 복사하고, 복사본에 대한 mutation을 수행하고 반환하는 boilerplate가 존재한다.
    - 큰 app state에 대하여 복사 프로세스가 크게 효율적이지 않다.
- `inout` 을 이용하면 위의 문제를 해결할 수 있다.
    - `(A, B) -> (A, C)` 와 같이 좌측 우측 모두에 parameter가 등장할 경우, `(inout A, B) -> C`  로 변경할 수 있다.