//
//  AppAction.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation

enum AppAction {
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    case favoritePrimes(FavoritePrimesAction)
}

func appReducer(value: inout AppState, action: AppAction) -> Void {
    switch action {
    case .counter(.decrTapped):
        value.count -= 1
    case .counter(.incrTapped):
        value.count += 1
    case .primeModal(.saveFavoritePrimeTapped):
        value.favoritePrimes.append(value.count)
        value.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(value.count)))
    case .primeModal(.removeFavoritePrimeTapped):
        value.favoritePrimes.removeAll(where: { $0 == value.count })
        value.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(value.count)))
    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = value.favoritePrimes[index]
            value.favoritePrimes.remove(at: index)
            value.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
        }
    }
}

