//
//  PrimeModalTests.swift
//  PrimeModalTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
@testable import PrimeModal

class PrimeModalTests: XCTestCase {
    
    func testExample() throws {
        var state = (count: 2, favoritePrimes: [3, 5])
        primeModalReducer(state: &state, action: .saveFavoritePrimeTapped)
        XCTAssertEqual(state, (2, [3, 5, 2]))
    }
    
}
