//
//  PrimeModalTests.swift
//  PrimeModalTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
@testable import PrimeModal

class PrimeModalTests: XCTestCase {
    
    func testSaveFavoritePrimesTapped() throws {
        var state = (count: 2, favoritePrimes: [3, 5])
        let effects = primeModalReducer(state: &state, action: .saveFavoritePrimeTapped)
        
        let (count, favoritePrimes) = state
        XCTAssertEqual(count, 2)
        XCTAssertEqual(favoritePrimes, [3, 5, 2])
        XCTAssert(effects.isEmpty)
    }
    
    func testRemoveFavoritePrimeTapped() {
      var state = (count: 3, favoritePrimes: [3, 5])

      let effects = primeModalReducer(state: &state, action: .removeFavoritePrimeTapped)

      let (count, favoritePrimes) = state
      XCTAssertEqual(count, 3)
      XCTAssertEqual(favoritePrimes, [5])
      XCTAssert(effects.isEmpty)
    }
    
}
