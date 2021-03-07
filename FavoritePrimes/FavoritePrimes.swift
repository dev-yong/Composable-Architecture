//
//  FavoritePrimes.swift
//  FavoritePrimes
//
//  Created by 이광용 on 2020/11/08.
//

import Foundation
import Core
import Combine

public enum FavoritePrimesAction: Equatable {
    case deleteFavoritePrimes(IndexSet)
    case loadedFavoritePrimes([Int])
    case saveButtonTapped
    case loadButtonTapped
}

public struct FavoritePrimesEnvironment {
    var fileClient: FileClient
}

extension FavoritePrimesEnvironment {
    
    public static let live = FavoritePrimesEnvironment(fileClient: .live)
    #if DEBUG
    public static let mock = FavoritePrimesEnvironment(
        fileClient: FileClient(
            load: { _ in Effect<Data?>.sync {
                try! JSONEncoder().encode([2, 31])
            } },
            save: { _, _ in .fireAndForget {} }
        )
    )
    #endif
    
}

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
    action: FavoritePrimesAction,
    environment: FavoritePrimesEnvironment
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
            environment.fileClient
                .save(
                    "favorite-primes.json",
                    try! JSONEncoder().encode(state)
                )
                .fireAndForget()
        ]
    case .loadButtonTapped:
        return [
            environment.fileClient.load("favorite-primes.json")
                .compactMap { $0 }
                .decode(type: [Int].self, decoder: JSONDecoder())
                .catch { _ in Empty(completeImmediately: true) }
                .map(FavoritePrimesAction.loadedFavoritePrimes)
                //.merge(with: Empty(completeImmediately: false))
                .eraseToEffect()
        ]
    }
}
