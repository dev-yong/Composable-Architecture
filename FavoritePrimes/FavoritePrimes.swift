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
    var fileClient: FileClient
}

extension FavoritePrimesEnvironment {
    static let live = FavoritePrimesEnvironment(fileClient: .live)
}

var Current = FavoritePrimesEnvironment.live

struct FileClient {
    var load: (_ fileName: String) -> Effect<Data?>
    var save: (_ fileName: String, _ data: Data) -> Effect<Never>
}

extension FileClient {
    
    static let live = FileClient { (fileName) -> Effect<Data?> in
        return .sync { () -> Data? in
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl
                .appendingPathComponent(fileName)
            return try? Data(contentsOf: favoritePrimesUrl)
        }
    } save: { (fileName, data) -> Effect<Never> in
        return .fireAndForget {
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(
                .documentDirectory,
                .userDomainMask, true
            )[0]
            let documentsUrl = URL(fileURLWithPath: documentsPath)
            let favoritePrimesUrl = documentsUrl.appendingPathComponent(fileName)
            try! data.write(to: favoritePrimesUrl)
        }
    }

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
        return [
            Current.fileClient
                .save(
                    "favorite-primes.json",
                    try! JSONEncoder().encode(state)
                )
                .fireAndForget()
        ]
    case .loadButtonTapped:
        return [loadEffect()]
    }
}
