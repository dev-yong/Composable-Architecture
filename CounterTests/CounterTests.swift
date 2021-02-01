//
//  CounterTests.swift
//  CounterTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
import Core
@testable import Counter

class CounterTests: XCTestCase {
    
    func assert<Value, Action>(
        initialValue: Value,
        reducer: Reducer<Value, Action>,
        steps: [(action: Action, update: (inout Value) -> Void, file: StaticString, line: UInt)]
    ) where Value: Equatable {
        var state = initialValue
        steps.forEach {
            var expected = state
            _ = reducer(&state, $0.action)
            $0.update(&expected)
            XCTAssertEqual(state, expected, file: file, line: line)
        }
    }
    
    override func setUp() {
        super.setUp()
        Current = .mock
    }
    
    func testIncrButtonTapped() {
        assert(
          initialValue: CounterViewState(count: 2),
          reducer: counterViewReducer,
            steps: [
                (.counter(.incrTapped), { $0.count = 3 }, #file, #line),
                (.counter(.incrTapped), { $0.count = 4 }, #file, #line),
                (.counter(.decrTapped), { $0.count = 5 }, #file, #line)
            ]
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
        
        var state = CounterViewState(
            alertNthPrime: nil,
            isNthPrimeButtonDisabled: false
        )
        var expected = state
        var effects = counterViewReducer(&state, .counter(.nthPrimeButtonTapped))
        
        expected.isNthPrimeButtonDisabled = true
        
        XCTAssertEqual(state, expected)
        XCTAssertEqual(effects.count, 1)
        
        var nextAction: CounterViewAction!
        let receivedCompletion = self.expectation(description: "receiveCompletion")
        let cancellation = effects[0].sink(
            receiveCompletion: { _ in receivedCompletion.fulfill() },
            receiveValue: { action in
                nextAction = action
                XCTAssertEqual(action, .counter(.nthPrimeResponse(17)))
            })
        self.wait(for: [receivedCompletion], timeout: 0.1)
        
        effects = counterViewReducer(&state, nextAction)
        expected.alertNthPrime = PrimeAlert(prime: 17)
        expected.isNthPrimeButtonDisabled = false
        
        XCTAssertEqual(state, expected)
        XCTAssertTrue(effects.isEmpty)
        
        effects = counterViewReducer(&state, .counter(.alertDismissButtonTapped))
        expected.alertNthPrime = nil
        
        XCTAssertEqual(state, expected)
        XCTAssertTrue(effects.isEmpty)
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
