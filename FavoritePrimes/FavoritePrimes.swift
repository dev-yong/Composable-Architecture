//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by 이광용 on 2020/11/08.
//

import Foundation
import Core

public enum FavoritePrimesAction {
    case deleteFavoritePrimes(IndexSet)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
    case loadButtonTapped
}

public func favoritePrimesReducer(
    state: inout [Int],
    action: FavoritePrimesAction
) -> Effect<Void> {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
        return {}
    case let .loadedFavoritePrimes(favoritePrimes):
        state = favoritePrimes
        return {}
    case .saveButtonTapped:
        let state = state
        return {
            let data = try! JSONEncoder().encode(state)
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent("favorite-primes.json")
            try! data.write(to: favoritePrimesUrl)
        }
    case .loadButtonTapped:
        return {
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent("favorite-primes.json")
            guard
                let data = try? Data(contentsOf: favoritePrimesUrl),
                let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
            else { return }
            
            self.store.send(.favoritePrimesLoaded(favoritePrimes))
        }
    }
}

