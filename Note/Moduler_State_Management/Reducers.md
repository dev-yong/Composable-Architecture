# Modular State Management: Reducers

### [What does modularity mean?](https://www.pointfree.co/collections/composable-architecture/modularity/ep72-modular-state-management-reducers#t438)

- Module
  - Application 에 import 되어질 수 있는 코드 단위
  - 공개하도록 결정한 모든 종류의 기능과 행동에 대한 public interface이다.
  - Module은 importer가 행하는 모든 것에 대하여 접근할 수 없다.
- Application을 module 단위로 쪼개는 것은 매우 중요하다.
  - 개별적으로 구축, 테스트, 배포할 수 있는 단위에 대하여 더욱 쉽게 이해할 수 있다.
  - 그렇게 되면, applciation는 모든 unit을 import하여 그것들을 compose할 수 있다.

### [Modularizing our reducers](https://www.pointfree.co/collections/composable-architecture/modularity/ep72-modular-state-management-reducers#t557)

- 여태까지 구성한 모든 reducer는 구성 요소의 로직을 설명하는 독립적인 단위이다. 
- 따라서, reducer들을 자체 모듈로 추출할 수 있어야 한다.
- `primeModalReducer` 는  `AppState` 와 연관되어 있기 때문에 필요로 하는 하위 집합 state만 의존할 수 있도록 `PrimeModalState` 를 추가한다. 

### [Modularizing the Composable Architecture](https://www.pointfree.co/collections/composable-architecture/modularity/ep72-modular-state-management-reducers#t653)

- `Store` 및 Reducer-composing function 을 포함하여 아키텍처를 강화하는 핵심 라이브러리 코드가 있으므로 "Core"라는 프레임 워크를 추가한다.