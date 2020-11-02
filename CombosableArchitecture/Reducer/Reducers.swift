//
//  AppReducer.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/11.
//

import Foundation
import Core

func activityFeed(
  _ reducer: @escaping (inout AppState, AppAction) -> Void
) -> (inout AppState, AppAction) -> Void {

    return { state, action in
        
        switch action {
        
        // activity feed에 중요하지 않다.
        case .counter:
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
        reducer(&state, action)
    }
}

let appReducer = combine(
    pullback(counterReducer, value: \.count),
    primeModalReducer,
    pullback(favoritePrimesReducer, value: \.favoritePrimes)
)

func counterReducer(state: inout Int, action: AppAction) -> Void {
    
    switch action {
    case . counter(.decrTapped):
        state -= 1
    case .counter(.incrTapped):
        state += 1
    default:
        break
    }
}

func primeModalReducer(state: inout AppState, action: AppAction) -> Void {
    
    switch action {
    
    case .primeModal(.saveFavoritePrimeTapped):
        state.favoritePrimes.append(state.count)
    case .primeModal(.removeFavoritePrimeTapped):
        state.favoritePrimes.removeAll(where: { $0 == state.count })
    default:
        break
    }
}

func favoritePrimesReducer(state: inout [Int], action: AppAction) -> Void {
    
    switch action {
    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            state.remove(at: index)
        }
    default:
        break
    }
}
