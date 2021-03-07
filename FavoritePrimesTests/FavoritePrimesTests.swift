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
            action: .deleteFavoritePrimes([2]),
            environment: .mock
        )

        XCTAssertEqual(state, [2, 3, 7])
        XCTAssert(effects.isEmpty)
    }
    
    func testSaveButtonTapped() {
        var didSave = false
        var environment = FavoritePrimesEnvironment.mock
        environment.save = { _, data in
            .fireAndForget {
                didSave = true
            }
        }
        
        var state = [2, 3, 5, 7]
        
        let effects = favoritePrimesReducer(
            state: &state,
            action: .saveButtonTapped,
            environment: environment
        )
        
        XCTAssertEqual(state, [2, 3, 5, 7])
        XCTAssertEqual(effects.count, 1)
        
        _ = effects[0].sink { _ in XCTFail() }
        XCTAssert(didSave)
    }
    
    func testLoadFavoritePrimesFlow() {
        var environment = FavoritePrimesEnvironment.mock
        environment.load = { _ in
            .sync {
                try! JSONEncoder().encode([2, 31])
            }
        }

        var state = [2, 3, 5, 7]
        
        var effects = favoritePrimesReducer(
            state: &state,
            action: .loadButtonTapped,
            environment: environment
        )

         XCTAssertEqual(state, [2, 3, 5, 7])
         XCTAssertEqual(effects.count, 1)
        
        var nextAction: FavoritePrimesAction!
        let receivedCompletion = self.expectation(description: "receivedCompletion")
        _ = effects[0].sink(
          receiveCompletion: { _ in receivedCompletion.fulfill() },
          receiveValue: { action in
            nextAction = action
            XCTAssertEqual(action, .loadedFavoritePrimes([2, 31]))
        })
        self.wait(for: [receivedCompletion], timeout: 0)
        
        effects = favoritePrimesReducer(
            state: &state,
            action: nextAction,
            environment: environment
        )

        XCTAssertEqual(state, [2, 31])
        XCTAssert(effects.isEmpty)
    }
    
}
