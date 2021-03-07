# Testable State Management: Ergonomics

### [Introduction](https://www.pointfree.co/collections/composable-architecture/testing/ep84-testable-state-management-ergonomics#t5)

- 사용자가 UI에서 다양한 작업을 수행함에 따라 애플리케이션 상태가 어떻게 변화하는지 테스트 할뿐만 아니라, 올바른 effect가 실행되고 올바른 action을 반환하는 가에 대하여 확인함으로써 effect에 대한 end-to-end testing 또한 수행하였다.
- 하지만, 현재의 테스트는 많은 코드를 포함하고 있다.
  - expectation을 생성한다.
  - effect를 실행한다.
  - expectation을 기다린다.
  - expectation을 충족한다.
  - 다음 action을 캡쳐한다.
  - 어떤 action을 취하였는지 확인하고 reducer에 다시 피드백한다.
- 아키텍쳐에 대한 expectation를 확인하기 위하여 할 일의 형태인 기본적인 필수 사항에 집중해야할 필요가 있다.
- 초기 state를 제공하고 테스트하려는 reducer를 제공한 다음, 일련의 action과 expectation을 제공하는 것으로 요약된다. 
  - 이상적으로 boilerplate가 거의 없는 선언형 방식이다.

### [Simplifying testing state](https://www.pointfree.co/collections/composable-architecture/testing/ep84-testable-state-management-ergonomics#t123)

- 우리의 관심사는  `count: 3`  만이 해당한다.
  -  `count` 만이 초기 state와 다른 유일한 필드이지만 각 initializer의 호출을 수동으로 검사하고 비교하지 않고 변경된 필드(변경사항이 있는 경우)를 확인하기가 어렵다.
  - 따라서, 의도가 더 잘 표현되는 assertion message를 사용할 필요가 있다.
    - 하지만, message는 assertion이 실제로 캡쳐하고자 하는 내용에 대하여 변경사항이 생긴다면, 테스트 코드를 더욱 장황하게 만들 것이다.
  - 만일 더 많은 필드를 갖는 state에 대한 테스트를 고려해본다면, 이러한 형태는 테스트가 매우 힘들어질 것임을 예상할 수 있다.

```swift
XCTAssertEqual(
  state,
  CounterViewState(
    alertNthPrime: nil,
    count: 3,
    favoritePrimes: [3, 5],
    isNthPrimeButtonDisabled: false
  ),
  "Expected count to increment to 3"
)
```

- 테스트가 expectation를 좀 더 직접적으로 설명하도록 assert하는 방법을 단순화하는 것이 더 나을 수 있다.
  1. Reducer에 원본 state를 공급하기 전에, 변경가능한 복사본을 만든다.
  2. 예상되는 결과를 해당 복사본에 적용한다.
  3. 원본과 복사본을 assert한다.

```swift
var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )

var expected = state
let effects = counterViewReducer(&state, .counter(.incrTapped))

expected.count = 3
XCTAssertEqual(
    state,
    expected
)
XCTAssertTrue(effects.isEmpty)
```

- 하지만 테스트의 상당 부분이 여전히 state의 initializer에 전념하고 있다.
  - 테스트의 시작 시, 항상 전체적인 initializer를 호출있으며, 작업이 필요한 것보다 훨씬 더 취약해지게 된다.
  - `CounterViewState` 구조체에 변경이 생길 경우, 모든 테스트는 컴파일 에러가 발생할 것이고 실질적인 테스트에 영향을 주지않는 부분이라도 모두 업데이트해야할 것이다.
- `CounterViewState` 의 initializer를 합리적인 기본값들로 구성하여, 테스트에 집중하고자 하는 필드에 대해서만 고려한다.

```swift
func testIncrButtonTapped() {
    var state = CounterViewState(
        count: 2
    )
    
    var expected = state
    let effects = counterViewReducer(&state, .counter(.incrTapped))
    
    expected.count = 3
    XCTAssertEqual(
        state,
        expected
    )
    XCTAssertTrue(effects.isEmpty)
}
```

### [The shape of a test](https://www.pointfree.co/collections/composable-architecture/testing/ep84-testable-state-management-ergonomics#t410)

- 테스트가 많이 간소화되었지만, 아직도 많은 일들이 벌어지고 있다.
  - Effect에는 많은 boilerplate가 연결되어 있다.
    - 수동으로 유지하고, `sink`  method로 수동으로 수행하고, expectation 생성하고, 대기하고, completion block에서 수행하는 것과 관련된 `XCTestExpectation` 를 수행해야한다.
  - 테스트 과정에서 테스트가 관리하고 reducer에 공급하는 지역적이고 변경 가능한 state가 있다. 
    - 변이를 어떤 범위, 심지어 국소 범위에까지 도입하는 것은 추론하는 것을 더 어렵게 만든다. 
    - 그리고  `expected` 복사본의 형태로 변이 가능한 상태를 두 배로 도입하였다.
- 테스트는 매우 명백한 형태를 가지고 있지만, 이러한 assertion을 하기 위해서는 우리가 맞혀야 할 것들이 많이 있다. 
  - 작성한 모든 테스트가 동일한 스크립트를 따르는 것을 알 수 있다. 
  - 초기 state를 구성하고 reducer를 준비한 다음, user action 스크립트를 살펴보고 그 과정에서 우리의 모든 기대치를 확인한다.

```swift
func assert<Value, Action>(
  initialValue: Value,
  reducer: Reducer<Value, Action>,
  steps: [(action: Action, update: (inout Value) -> Void)]
) where Value: Equatable {
    var state = initialValue
    steps.forEach {
        var expected = state
        _ = reducer(&state, $0.action)
        $0.update(&expected)
        XCTAssertEqual(state, expected)
    }
}
```

### [Improving test feedback](https://www.pointfree.co/collections/composable-architecture/testing/ep84-testable-state-management-ergonomics#t850)

- `XCTest`는 일부 Swift 기능을 활용하여 오류를 인라인으로 표시하므로 동일한 방법으로 `assert` helper method를 향상시킬 수 있다.

```swift
func assert<Value: Equatable, Action>(
  initialValue: Value,
  reducer: Reducer<Value, Action>,
  steps: (action: Action, update: (inout Value) -> Void)...,
  file: StaticString = #file,
  line: UInt = #line
)
```


  - 나아지긴 하였지만, 아직 이상적이지는 않다.

      - 실제 실패는 다른 줄에서 발생하지만, 로그에 찍히는 바로는 `assert` method가 호출된 위치로 찍히고 있다.
      - 위치를 전달하는 방법은 `steps` 를  `file` 및 `line` 필드를 추가하여 업그레이드한다.

```swift
steps: (action: Action, update: (inout Value) -> Void, file: StaticString, line: UInt)...,
```

- 모든 코드에 `#file`, `#line` 을 추가하는 것은 꽤나 귀찮다.
  - `steps` 튜플을 적절한 초기값을 갖는 initializer 사용하여 struct로 업그레이드한다.

```swift
struct Step<Value, Action> {
    let action: Action
    let update: (inout Value) -> Void
    let file: StaticString
    let line: UInt
    
    init(
        _ action: Action,
        _ update: @escaping (inout Value) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.action = action
        self.update = update
        self.file = file
        self.line = line
    }
}
```

### [Actions sent and actions received](https://www.pointfree.co/collections/composable-architecture/testing/ep84-testable-state-management-ergonomics#t1157)

- action이 보내지는 과정에서 reducer의 state에 대한 세부적인 변경 사항을 설명하기 위한 도메인 특정 언어가 있지만 effect의 테스트 작업을 다시 캡처하지는 않는다.

  - action이 store의 reducer에 공급되는 방법이 2가지 있다.
    - User action을 통해 명시적으로 전송되거나
    - Effect의 결과를 통해 시스템으로 다시 공급된다.
  - 사용자가 어떠한 action을 취하고, action이 시스템에 피드백될 것으로 기대하는 행동을 선언하는 스크립트를 가지도록 도메인 특정 언어로 분리한다.

- 이상적으로 `Step` 은 어떤 action이 store로 전송되어야하는지와 어떤 action이 effect에 의해 수신되었는지 서술하여야 한다.

```swift
enum StepType {
  case send
  case receive
}
```

- `StepType`을 사용하여 `Step`이 action을 보내도록 지시할 때 정상적으로 reducer를 호출 할 수 있지만 생성된 effect도 추적하는 것을 기대할 수 있다. 
  - 그런 다음 action을 수신하고 있다는 step을 만나면 추적중인 array에서 첫 번째 effect를 가져 와서 실행하고 생성된 action이 step의 actoion인지 확인한다.
    - 아래의 코드는 현재 send일 경우, effect를 수행하고 있지 않는다.

```swift
func assert<Value, Action>(
    initialValue: Value,
    reducer: Reducer<Value, Action>,
    steps: Step<Value, Action>...
) where Value: Equatable, Action: Equatable {
    var state = initialValue
    var effects: [Effect<Action>] = []
    var cancellables: [AnyCancellable] = []

    steps.forEach { step in
        var expected = state
        switch step.type {
        case .send:
            // Reducer에서 반한된 effect를 트래킹하기 위하여
            // 반환되는 effect들을 지닐 수 있는 `effects`를 반복문 외부에 도입하도록 한다.
            effects.append(contentsOf: reducer(&state, step.action))
        case .receive:
            // `send`에 의한 action을 `receive`하였기에,
            // `receive`에서 `effects`의 첫 번째 effect를 pop하도록 한다.
            let effect = effects.removeFirst()
            // Expectation을 도입하여 effect가 완료된 후의 action을 추출할 수 있다.
            var action: Action!
            let receivedCompletion = XCTestExpectation(description: "receivedCompletion")
            // 다음으로 `sink`로 effect를 실행하고 완료 시 expectation을 충족하고 수신 시 다음 action을 할당한다.
            let sink = effect.sink(
              receiveCompletion: { _ in receivedCompletion.fulfill() },
              receiveValue: { action = $0 }
            )
            cancellables.append(sink)
            if XCTWaiter.wait(for: [receivedCompletion], timeout: 0.01) != .completed {
              XCTFail(
                "Timed out waiting for the effect to complete",
                file: step.file,
                line: step.line
              )
            }
            XCTAssertEqual(action, step.action, file: step.file, line: step.line)
            // 반환되는 effect를 작업중인 배열에 추가하도록 한다.
            effects.append(contentsOf: reducer(&state, action))
        }
        step.update(&expected)
        XCTAssertEqual(state, expected, file: step.file, line: step.line)
    }
}
```

### [Assertion edge cases](https://www.pointfree.co/collections/composable-architecture/testing/ep84-testable-state-management-ergonomics#t1905)

- 아직 모든 케이스를 확인할 수 없다.
- Effect로부터 acion을 받을 것으로 예상되는 단계를 지워본다.

```swift
assert(
    initialValue: CounterViewState(
        alertNthPrime: nil,
        isNthPrimeButtonDisabled: false
    ),
    reducer: counterViewReducer,
    steps:
        Step(.send, .counter(.nthPrimeButtonTapped)) {
            $0.isNthPrimeButtonDisabled = true
        },
      // Step(.receive, .counter(.nthPrimeResponse(15))) {
      //     $0.alertNthPrime = PrimeAlert(prime: 15)
      //     $0.isNthPrimeButtonDisabled = false
      // },
    Step(.send, .counter(.alertDismissButtonTapped)) {
        $0.alertNthPrime = nil
    }
)
```

- 하지만, 수행을 해야하는 effect가 존재하고 있음에도 불구하고, 테스트는 여전히 통과한다.
- 이는, 우리가 명시적으로 action을 받을 것으로 예상할 때만 effect를 고려하기 때문에 발생한다.
- `assert`의 `send`는 일부 보류 중인 effect를 설명하지 않은 경우에도 진행된다

```swift
effects.append(contentsOf: reducer(&state, step.action))
```

- 전송된 action에 대해 reducer를 실행하기 전에 대기중인 효과가 없는지 확인하도록 한다.

```swift
if effects.isEmpty {
    XCTFail(
      "Action sent before handling \(effects.count) pending effect(s)",
      file: step.file,
      line: step.line
    )
}
effects.append(contentsOf: reducer(&state, step.action))
```

```swift
Step(.send, .counter(.nthPrimeButtonTapped)) {
        $0.isNthPrimeButtonDisabled = true
      }//,
//      Step(.receive, .counter(.nthPrimeResponse(17))) {
//        $0.alertNthPrime = PrimeAlert(prime: 17)
//        $0.isNthPrimeButtonDisabled = false
//      },
//      Step(.send, .counter(.alertDismissButtonTapped)) {
//        $0.alertNthPrime = nil
//      }

```

- 위의 테스트 자체는 통과가 되겠지만,  `nthPrimeResponse`  action이 반환하는 효과는 테스트되지 않았다. 
  - **모든 Effect에 대해 테스트하는 것을 잊지 않도록 helper가 이러한 실수를 포착할 수 있도록 한다.**
  - 주어진 모든 단계를 반복 한 후 effect 배열에 보류중인 효과가 포함되어 있으면 실패해야 한다.

```swift
//      Step(.send, .counter(.nthPrimeButtonTapped)) {
//          $0.isNthPrimeButtonDisabled = true
//      }
Step(.receive, .counter(.nthPrimeResponse(15))) {
    $0.alertNthPrime = PrimeAlert(prime: 15)
    $0.isNthPrimeButtonDisabled = false
},
Step(.send, .counter(.alertDismissButtonTapped)) {
    $0.alertNthPrime = nil
}
```

- effects가 없을 때 receive를 하게 될 경우, 아래의 구문에서 fatalError를 접하게 되기에 이를 위하여 effects의 존재 유무를 확인하도록 한다.
  - 배열의 removeFirst 메서드는 선택 사항이 아닌 요소를 반환하므로 이러한 요소가 없으면 충돌하게 된다. 
  - 그리고 테스트가 effect를 기대하고 아무 effect가 없을 때 실패하기를 원하지만 전체 테스트에서 crash가 발생하기를 원치는 않는다.

```swift
// AS-IS
case .receive:
  let effect = effects.removeFirst() 

// TO-BE
case .receive:
guard !effects.isEmpty else {
    XCTFail(
        "No pending effects to receive from",
        file: step.file,
        line: step.line
    )
    break
}
let effect = effects.removeFirst()
```