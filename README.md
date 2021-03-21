# Composable Architecture [WIP]

[Pointfree에서 제공하는 Composable Architecture](https://www.pointfree.co/collections/composable-architecture) 에 대한 공부 기록을 위한 Repository입니다.

## Reducers and Stores

### [Reducers](/Reducer_and_Stores/Reducers.md)

- Value Semantic을 활용하고 얇은 Wrapper인 `Store` 를 도입하라.
- 일관적인 방법으로 mutation을 수행하라.
- User Action에 대하여 정의하라.
- BoilerPlate 코드를 없애기 위하여, copy process를 줄이기 위하여 `inout` 을 이용하자.

### State Pullbacks

- 

### Action Pullbacks

- 

### [Higher-order Reducers](/Note/Reducer_and_Stores/Higher-Order_Reducers.md)

- Reducer를 입력으로 사용하고 Reducer를 출력으로 반환하는 Reducer
- 기능별 Logic 을 한 곳에 집중시킬 수 있다.
- 아직까지는 composition nesting이 지저분해지는 단점이 존재한다.

## Moduler State Management

### [Reducers](/Note/Moduler_State_Management/Reducers.md)

- 모듈이란 Application에 import 되어질 수 있는 코드의 단위 이다.
- Application을 module 단위로 쪼개라.
- Reducer 들을 자체 모듈로 추출하자.

### [View State](/Note/Moduler_State_Management/View_State.md)

- View 들에 대하여 modularizing을 하자.
- Global Store의 value를 Local Store의 value로 변환하자.
- Global Store의 파생된 변화를 Local Store가 받도록 하자.

### [View Actions](/Note/Moduler_State_Management/View_Action.md)

- AppAction에 의존하는 것을 완전히 분리 시키자.
- Global Action 대신 Local Action을 보내자.

## Side Effects

### [Synchronous Effect](/Note/SideEffects/SynchronousEffects.md)

- 단순한 synchronous side effect른 만들자.
- Reducer에 모든 로직을 이동하여 View는 logic-less를 유지하라.
- 작업 실행의 책임은 Store가 갖는다.

### [Unidirectional Effects](/Note/SideEffects/UnidirectionalEffects.md)

- effect의 결과를 가져 와서 reducer 바로 되돌리는 방법이 필요로 하다.
- 데이터는 한 가지 방식으로만 변경된다.

### [Asynchronous Effects](/Note/SideEffects/AsynchronousEffects.md)

- Asynchronous한 것을 synchronous effect로 변경해보자.
- Asynchronous effect를 만들자.

### [The Point](/Note/SideEffects/ThePoint.md)

- Asynchronous effect signagure를 감싸는 struct를 만들다.
- Asynchronous와 연관된 작업들을 Effect로 만들고, 분리하도록 하자.

### [The Combine Framework And Effects](/Note/SideEffects/TheCombineFrameworkAndEffects.md)

- Effect에 Combine의 publisher를 적용하도록하자.
- Fire-and-forget, sync, async Effect의 변경된 인터페이스에 대한 대응을 하도록 하자.

## Testing

### [Reducer](/Note/Testing/Reducer.md)

### [Effects](/Note/Testing/Effects.md)

### [Ergonomics](/Note/Testing/Ergonomics.md)
## Depednecy

### [Dependency Injection Made Composable](/Note/Dependency/Dependency_Injection_Made_Composable.md)

### [Dependency Injection Made Modular](/Note/Dependency/Dependency_Injection_Made_Modular.md)

## Adaptive State Management

### [Performance](/Note/Adaptive_State_Management/Performance.md)

