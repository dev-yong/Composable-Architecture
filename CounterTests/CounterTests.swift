//
//  CounterTests.swift
//  CounterTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
import Core
import Combine
@testable import Counter

enum StepType {
  case send
  case receive
}

struct Step<Value, Action> {
    let type: StepType
    let action: Action
    let update: (inout Value) -> Void
    let file: StaticString
    let line: UInt
    
    init(
        _ type: StepType,
        _ action: Action,
        _ update: @escaping (inout Value) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.type = type
        self.action = action
        self.update = update
        self.file = file
        self.line = line
    }
}

func assert<Value, Action>(
    initialValue: Value,
    reducer: Reducer<Value, Action>,
    steps: Step<Value, Action>...,
    file: StaticString = #file,
    line: UInt = #line
) where Value: Equatable, Action: Equatable {
    var state = initialValue
    var effects: [Effect<Action>] = []
    var cancellables: [AnyCancellable] = []

    steps.forEach { step in
        var expected = state
        switch step.type {
        case .send:
            // 전송된 action에 대해 reducer를 실행하기 전에 대기중인 효과가 없는지 확인하도록 한다.
            if effects.isEmpty {
                XCTFail(
                  "Action sent before handling \(effects.count) pending effect(s)",
                  file: step.file,
                  line: step.line
                )
            }
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
            cancellables.append(
              effect.sink(
                receiveCompletion: { _ in
                  receivedCompletion.fulfill()
              },
                receiveValue: { action = $0 }
              )
            )
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
    
    if !effects.isEmpty {
      XCTFail(
        "Assertion failed to handle \(effects.count) pending effect(s)",
        file: file,
        line: line
      )
    }
}


class CounterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Current = .mock
    }
    
    func testIncrButtonTapped() {
        assert(
          initialValue: CounterViewState(count: 2),
            reducer: counterViewReducer,
            steps: Step(.send, .counter(.incrTapped)) { $0.count = 2 },
            Step(.send, .counter(.incrTapped)) { $0.count = 4 },
            Step(.send, .counter(.decrTapped)) { $0.count = 5 }
        )
    }
   
    func testDecrButtonTapped() {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )
        let effects = counterViewReducer(&state, .counter(.decrTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 1,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }
    
    func testNthPrimeButtonHappyFlow() {
        
        Current.nthPrime = { _ in .sync { 17 } }
        
        assert(
            initialValue: CounterViewState(
                alertNthPrime: nil,
                isNthPrimeButtonDisabled: false
            ),
            reducer: counterViewReducer,
            steps:
                Step(.send, .counter(.nthPrimeButtonTapped)) {
                    $0.isNthPrimeButtonDisabled = true
                }
//            Step(.receive, .counter(.nthPrimeResponse(15))) {
//                $0.alertNthPrime = PrimeAlert(prime: 15)
//                $0.isNthPrimeButtonDisabled = false
//            },
//            Step(.send, .counter(.alertDismissButtonTapped)) {
//                $0.alertNthPrime = nil
//            }
        )
    }
    
    func testNthPrimeButtonUnhappyFlow() {
        Current.nthPrime = { _ in .sync { nil } }
        
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )
        
        var effects = counterViewReducer(&state, .counter(.nthPrimeButtonTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: true
            )
        )
        XCTAssertEqual(effects.count, 1)
        
        var nextAction: CounterViewAction!
        let receivedCompletion = self.expectation(description: "receivedCompletion")
        let cancellation = effects[0].sink(
            receiveCompletion: { _ in
                receivedCompletion.fulfill()
            },
            receiveValue: { action in
                XCTAssertEqual(action, .counter(.nthPrimeResponse(nil)))
                nextAction = action
            }
        )
        self.wait(for: [receivedCompletion], timeout: 0.1)
        
        effects = counterViewReducer(&state, nextAction)

        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssertTrue(effects.isEmpty)
    }
    
    func testPrimeModal() {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )
        
        var effects = counterViewReducer(&state, .primeModal(.saveFavoritePrimeTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5, 2],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
        
        effects = counterViewReducer(&state, .primeModal(.removeFavoritePrimeTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 2,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssert(effects.isEmpty)
    }

}
