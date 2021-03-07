# Dependency Injection Made Modular

### [Using the architecture’s environment](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep92-dependency-injection-made-modular#t54)

#### PrimeModal

- `PrimeModal` 모듈은 effect를 지니고 있지 않기 때문에 enivronment를 사용할 필요가 없다. 
  - 하지만, Reducer signature의 변경에 대한 적용이 필요로 하다.
  - Environment가 필요가 없기 때문에 `Void` 를 사용하여도 된다.
  - `Void`는 의미가 없는 environment를 나타내므로 작업을 수행하는 데 종속성이 필요하지 않는다.

```swift
func primeModalReducer(
  state: inout PrimeModalState,
  action: PrimeModalAction, 
  environment: Void
)
```

#### FavoritePrimes

- `FavoritePrimes` 모듈은 effect들을 지니고 있으며, `FavoritePrimesEnvironment` 의 종속성을 필요로 한다.
  - 이전에 전역변수로 들고 있던 `Current` 를 environment 인자로 대체한다.

```swift
func favoritePrimesReducer(
    state: inout [Int],
    action: FavoritePrimesAction,
    environment: FavoritePrimesEnvironment
)
```

- **App이 모듈화되어** 있기에 변경사항에 대하여 전체를 빌드할 필요없이 **해당 모듈만 빌드 및 테스트**하면 된다.

#### Counter

- `Counter` 모듈은 side effects가 있을 뿐아니라, 이전의 모듈들이 가지지 않는 새로운 것이 있다.
- `counterReducer` 에 `CounterEnvironment` 를 저용하도록 한다.
  - 다음으로 pullback에 대한 수정이 필요로 하다.
  - 이전까지는 state와 action에 대해서만 당겨왔지만, Local인 `counterReducer`와 `primeModalReducer`  가 두 기능을 모두 포함하는 더 큰 reducer에 어떻게 내장되어야하는지 설명할 수 있도록 **environment를 통합**하여야 한다.

```swift
public let counterViewReducer: Reducer<CounterViewState, CounterViewAction, CounterEnvironment> = combine(
    pullback(
        counterReducer,
        value: \CounterViewState.counter,
        action: \CounterViewAction.counter,
        environemnt: { $0 }
    ),
    pullback(
        primeModalReducer,
        value: \.primeModal,
        action: \.primeModal,
        environemnt: { _ in Void() }
    )
)
```

#### Application

- 기능 모듈에 정의된 모든 reducer와 view를 composite하여 전체 어플리케이션을 구성하도록 한다.
- `appReducer` 는 `counterViewReducer` 와 `favoritePrimesReducer` 로 구성되고,  **`AppEnvironment` 를 도입하여 각각의 reudcer에 대한 모든 의존성을 포함할 수 있게 한다.**

```swift
struct AppEnvironment {
    var counter: CounterEnvironment
    var favoritePrimes: FavoritePrimesEnvironment
}
```

- 각 기능의 reducer를 pullback할 때 AppEnvionment를 각 기능의 environment로 변환하는 방법을 기술한다.

```swift
let appReducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
  pullback(
    counterViewReducer,
    value: \AppState.counterView,
    action: \AppAction.counterView,
    environemnt: { $0.counter }
  ),
  pullback(
    favoritePrimesReducer,
    value: \.favoritePrimes,
    action: \.favoritePrimes,
    environemnt: { $0.favoritePrimes }
  )
)
```

### [Tuplizing the environment](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep92-dependency-injection-made-modular#t646)

- 각 기능 모듈에 대한 enviornment 구조체가 있으면 서로 의존성이 불필요하게 격리된다.
  
  - 각 구조체는 고유한 버전의 의존성을 유지하며 두 개의 서로 다른 기능이 동일한 종속성에 접근하기를 원할 수도 있으며 , 부모 environment에서 복제하도록 강제한다.
  
- **Environment 구조체의 기능은 필요하지 않다.**
  - **모든 method를 추가하거나, 변경하거나, protocol을 따를 필요가 없다.**
  - **필요한 것은 다중의 의존성을 한번에 전달할 수 있도록 하는 것 뿐**이다.
  - typealias와 tuple이 중첩된 의존성 문제를 평탄화하는 데 도움이 될 수 있다.
  
-  `FavoritePrimesEnvironment` 의 type alias를 `FileClinent` 로 한다.

```swift
public typealias FavoritePrimesEnvironment = FileClient
```

- `CounterEnvrionment` 에 `nthPrime` 의존성을 직접 할당한다.

```swift
public typealias CounterEnvironment = (Int) -> Effect<Int?>
```

- `AppEnvironment` 에서 중첩된 구조체를 사용하여 기능간에 의존성을 공유하기 어렵게 만드는 대신, 각 **기능에 필요한 모든 의존성을 포함하는 플랫한 tuple**을 만든다.

```swift
typealias AppEnvironment = (
  fileClient: FileClient,
  nthPrime: (Int) -> Effect<Int?>
)
```

- `AppEnvironment` 와 같은 root에서는 **단순한 의존성 목록을 갖는 것이 훨씬 더 좋다.** 
  - 그러면 reducer를 pullback할 때마다 때마다 어떤 종속성을 전달할지 결정할 수 있다.

- Tuple로 변경하며 자동완성과 관련된 것들을 잃어버렸다. Struct initializer는 자동 완성에 표시되지만 tuple typealias는표시되지 않는다.

### [Testing with the environment](https://www.pointfree.co/collections/composable-architecture/dependency-management/ep92-dependency-injection-made-modular#t1190)

- 이제 앱이 마침내 빌드되고 이전과 똑같이 작동하지만 기능에서 Global Environment에 대한 의존성을 제거하고 대신 명시 적으로 environment를 전달하고 있다.

#### Prime Modal

- `Void` 를 Environment로 사용하여  크게 할 일이 없다. `enviornment` 인자에 필요로 하는 void value만 전달하도록 한다.

#### FavoritePrimes

- `FileClinet` 의존성을 필요로 하며, 기존의 `Current` 는 제거하도록한다.

#### Counter

- Counter Test 에 앞서 `assert` helper가 environment 를 인지할 수 있도록 수정한다.

```swift
func assert<Value, Action, Environment>(
    initialValue: Value,
    reducer: Reducer<Value, Action, Environment>,
    environment: Environment,
    steps: Step<Value, Action>...,
    file: StaticString = #file,
    line: UInt = #line
)
```

