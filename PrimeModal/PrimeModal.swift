//
//  PrimeModal.swift
//  PrimeModal
//
//  Created by 이광용 on 2020/11/08.
//

import Foundation
import Core

public enum PrimeModalAction: Equatable {
    case saveFavoritePrimeTapped
    case removeFavoritePrimeTapped
}

public typealias PrimeModalState = (count: Int, favoritePrimes: [Int])

public func primeModalReducer(state: inout PrimeModalState, action: PrimeModalAction) -> [Effect<PrimeModalAction>] {
    switch action {
    case .removeFavoritePrimeTapped:
        state.favoritePrimes.removeAll(where: { $0 == state.count })
        return []
    case .saveFavoritePrimeTapped:
        state.favoritePrimes.append(state.count)
        return []
    }
}

