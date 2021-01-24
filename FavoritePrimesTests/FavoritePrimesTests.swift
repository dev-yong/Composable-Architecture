//
//  FavoritePrimesTests.swift
//  FavoritePrimesTests
//
//  Created by 이광용 on 2020/11/02.
//

import XCTest
@testable import FavoritePrimes

class FavoritePrimesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Current = .mock
    }
    
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
        var didSave = false
        Current.fileClient.save = { _, data in
            .fireAndForget {
                didSave = true
            }
        }
        
        var state = [2, 3, 5, 7]
        
        let effects = favoritePrimesReducer(
            state: &state,
            action: .saveButtonTapped
        )
        
        XCTAssertEqual(state, [2, 3, 5, 7])
        XCTAssertEqual(effects.count, 1)
        
        _ = effects[0].sink { _ in XCTFail() }
        XCTAssert(didSave)
    }
    
    func testLoadFavoritePrimesFlow() {
        Current.fileClient.load = { _ in
            .sync {
                try! JSONEncoder().encode([2, 31])
            }
        }

        var state = [2, 3, 5, 7]
        
        var effects = favoritePrimesReducer(
            state: &state,
            action: .loadButtonTapped
        )

         XCTAssertEqual(state, [2, 3, 5, 7])
         XCTAssertEqual(effects.count, 1)
        
        var nextAction: FavoritePrimesAction!
        _ = effects[0].sink { action in
          XCTAssertEqual(action, .loadedFavoritePrimes([2, 31]))
          nextAction = action
        }

        effects = favoritePrimesReducer(
            state: &state,
            action: nextAction
        )

        XCTAssertEqual(state, [2, 31])
        XCTAssert(effects.isEmpty)
    }
    
}
