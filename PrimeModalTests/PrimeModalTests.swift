//
//  PrimeModalTests.swift
//  PrimeModalTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
@testable import Counter
@testable import FavoritePrimes
@testable import PrimeModal

class PrimeModalTests: XCTestCase {
  func testSaveFavoritesPrimesTapped() {
    var state = (count: 2, favoritePrimes: [3, 5])
    let effects = primeModalReducer(state: &state, action: .saveFavoritePrimeTapped, environment: ())

    let (count, favoritePrimes) = state
    XCTAssertEqual(count, 2)
    XCTAssertEqual(favoritePrimes, [3, 5, 2])
    XCTAssert(effects.isEmpty)
  }

  func testRemoveFavoritesPrimesTapped() {
    var state = (count: 3, favoritePrimes: [3, 5])
    let effects = primeModalReducer(state: &state, action: .removeFavoritePrimeTapped, environment: ())

    let (count, favoritePrimes) = state
    XCTAssertEqual(count, 3)
    XCTAssertEqual(favoritePrimes, [5])
    XCTAssert(effects.isEmpty)
  }
}
