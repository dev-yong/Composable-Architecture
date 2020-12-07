//
//  AppReducer.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/11.
//

import Foundation
import Core
import Counter
import PrimeModal
import FavoritePrimes

func activityFeed(
  _ reducer: @escaping Reducer<AppState, AppAction>
) -> Reducer<AppState, AppAction> {

    return { state, action in
        
        switch action {
        
        // activity feed에 중요하지 않다.
        case .counter,
             .favoritePrimes(.loadedFavoritePrimes),
             .favoritePrimes(.saveButtonTapped),
             .favoritePrimes(.loadButtonTapped):
            break
        case .primeModal(.removeFavoritePrimeTapped):
            state.activityFeed.append(
                .init(
                    timestamp: Date(),
                    type: .removedFavoritePrime(state.count)
                )
            )
        case .primeModal(.saveFavoritePrimeTapped):
            state.activityFeed.append(
                .init(
                    timestamp: Date(),
                    type: .addedFavoritePrime(state.count)
                )
            )
        case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
            for index in indexSet {
                state.activityFeed.append(
                    .init(
                        timestamp: Date(),
                        type: .removedFavoritePrime(state.favoritePrimes[index])
                    )
                )
            }
        }
        let effect = reducer(&state, action)
        return effect
    }
}

let _appReducer: (inout AppState, AppAction) -> Effect = combine(
    pullback(counterReducer, value: \.count, action: \.counter),
    pullback(primeModalReducer, value: \.primeModal, action: \.primeModal),
    pullback(favoritePrimesReducer, value: \.favoritePrimes, action: \.favoritePrimes)
)

let appReducer = pullback(_appReducer, value: \.self, action: \.self)
