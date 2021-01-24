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

struct FavoritePrimesEnvironment {

}

struct FileClient<A> {
    var load: (_ fileName: String) -> Effect<Data?>
    var save: (_ fileName: String, _ data: Data) -> Effect<A>
}

public func favoritePrimesReducer(
    state: inout [Int],
    action: FavoritePrimesAction
) -> [Effect<FavoritePrimesAction>] {
    switch action {
    case let .deleteFavoritePrimes(indexSet):
        for index in indexSet {
            state.remove(at: index)
        }
        return []
    case let .loadedFavoritePrimes(favoritePrimes):
        state = favoritePrimes
        return []
    case .saveButtonTapped:
        let state = state
        return [saveEffect(favoritePrimes: state)]
    case .loadButtonTapped:
        return [loadEffect()]
    }
}

private func saveEffect(favoritePrimes: [Int]) -> Effect<FavoritePrimesAction> {
    return Effect.fireAndForget {
        let data = try! JSONEncoder().encode(favoritePrimes)
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        )[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let favoritePrimesUrl = documentsUrl
            .appendingPathComponent("favorite-primes.json")
        try! data.write(to: favoritePrimesUrl)
    }
}

private func loadEffect() -> Effect<FavoritePrimesAction> {
    return Effect<FavoritePrimesAction?>.sync {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        )[0]
        let documentsUrl = URL(fileURLWithPath: documentsPath)
        let favoritePrimesUrl = documentsUrl
            .appendingPathComponent("favorite-primes.json")
        guard
            let data = try? Data(contentsOf: favoritePrimesUrl),
            let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
        else { return nil }
        return .loadedFavoritePrimes(favoritePrimes)
    }
    .compactMap { $0 }
    .eraseToEffect()
}
