# Composable Architecture [WIP]

[Pointfree에서 제공하는 Composable Architecture](https://www.pointfree.co/collections/composable-architecture) 에 대한 공부 기록을 위한 Repository입니다.

## Reducers and Stores

### [Reducer](/Note/Reducer.md)

- Value Semantic을 활용하고 얇은 Wrapper인 `Store` 를 도입하라.
- 일관적인 방법으로 mutation을 수행하라.
- User Action에 대하여 정의하라.
- BoilerPlate 코드를 없애기 위하여, copy process를 줄이기 위하여 `inout` 을 이용하자.

### State Pullbacks

- 

### Action Pullbacks

- 

### [Higher-order Reducers](/NoteHigher-Order_Reducers.md)

- Reducer를 입력으로 사용하고 Reducer를 출력으로 반환하는 Reducer
- 기능별 Logic 을 한 곳에 집중시킬 수 있다.
- 아직까지는 composition nesting이 지저분해지는 단점이 존재한다.

### [Modular_State Management_Reducers](/Modular_State Management_Reducers.md)

- 모듈이란 Application에 import 되어질 수 있는 코드의 단위 이다.
- Application을 module 단위로 쪼개라.
- Reducer 들을 자체 모듈로 추출하자.