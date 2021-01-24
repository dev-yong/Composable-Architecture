//
//  FavoritePrimesTests.swift
//  FavoritePrimesTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
@testable import FavoritePrimes

class FavoritePrimesTests: XCTestCase {

    func testDeleteFavoritePrimes() {
        var state = [2, 3, 5, 7]

        let effects = favoritePrimesReducer(
            state: &state,
            action: .deleteFavoritePrimes([2])
        )

        XCTAssertEqual(state, [2, 3, 7])
        XCTAssert(effects.isEmpty)
    }
    
    func testSaveButtonTapped() {
        var state = [2, 3, 5, 7]
        
        let effects = favoritePrimesReducer(
            state: &state,
            action: .saveButtonTapped
        )
        
        XCTAssertEqual(state, [2, 3, 5, 7])
        XCTAssertEqual(effects.count, 1)
    }
    
}
