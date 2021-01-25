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
        var savedData: Data?
        Current.fileClient.save = { _, data in
            .fireAndForget {
                savedData = data
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
        
        XCTAssertNotNil(savedData)
        XCTAssertEqual(
            try JSONDecoder().decode([Int].self, from: savedData!),
            state
        )
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
        let receivedCompletion = self.expectation(description: "receivedCompletion")
        let receivedValue = self.expectation(description: "receivedValue")
        _ = effects[0].sink(
          receiveCompletion: { _ in receivedCompletion.fulfill() },
          receiveValue: { action in
            nextAction = action
            receivedValue.fulfill()
            XCTAssertEqual(action, .loadedFavoritePrimes([2, 31]))
        })
        self.wait(for: [receivedValue, receivedCompletion], timeout: 0)
        
        effects = favoritePrimesReducer(
            state: &state,
            action: nextAction
        )

        XCTAssertEqual(state, [2, 31])
        XCTAssert(effects.isEmpty)
    }
    
}
