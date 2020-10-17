# Composable Architecture [WIP]

[Pointfree에서 제공하는 Composable Architecture](https://www.pointfree.co/collections/composable-architecture) 에 대한 공부 기록을 위한 Repository입니다.

## Reducers and Stores

### [Reducer](/Note/Reducer.md)

- Value Semantic을 활용하고 얇은 Wrapper인 `Store` 를 도입하라.
- 일관적인 방법으로 mutation을 수행하라.
- User Action에 대하여 정의하라.
- BoilerPlate 코드를 없애기 위하여, copy process를 줄이기 위하여 `inout` 을 이용하자.