//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by 이광용 on 2020/11/08.
//

import Foundation

public enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
}

public func favoritePrimesReducer(state: inout [Int], action: FavoritePrimesAction) {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
    case let .loadedFavoritePrimes(favoritePrimes):
        state = favoritePrimes
    case .saveButtonTapped:
        let data = try! JSONEncoder().encode(state)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        )[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let favoritePrimesUrl = documentsUrl
            .appendingPathComponent("favorite-primes.json")
        try! data.write(to: favoritePrimesUrl)
    }
}

