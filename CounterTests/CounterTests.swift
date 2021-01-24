//
//  CounterTests.swift
//  CounterTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
@testable import Counter

class CounterTests: XCTestCase {

    func testIncrButtonTapped() {
        var state = CounterViewState(
            alertNthPrime: nil,
            count: 2,
            favoritePrimes: [3, 5],
            isNthPrimeButtonDisabled: false
        )
        let effects = counterViewReducer(&state, .counter(.incrTapped))
        
        XCTAssertEqual(
            state,
            CounterViewState(
                alertNthPrime: nil,
                count: 3,
                favoritePrimes: [3, 5],
                isNthPrimeButtonDisabled: false
            )
        )
        XCTAssertTrue(effects.isEmpty)
    }
}
