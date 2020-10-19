//
//  AppReducer.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/11.
//

import Foundation

let appReducer = combine(
    pullback(counterReducer, value: \.count),
    primeModalReducer,
    pullback(favoritePrimesReducer, value: \.favoritePrimesState)
)

func counterReducer(state: inout Int, action: AppAction) -> Void {
    
    switch action {
    
    case .counter(let counterAction):
        
        switch counterAction {
        
        case .incrTapped:
            state += 1
        case .decrTapped:
            state -= 1
        }
    default:
        break
    }
}

func primeModalReducer(state: inout AppState, action: AppAction) -> Void {
    
    switch action {
    
    case .primeModal(.saveFavoritePrimeTapped):
        state.favoritePrimes.append(state.count)
        state.activityFeed.append(.init(timestamp: Date(), type: .addedFavoritePrime(state.count)))
    case .primeModal(.removeFavoritePrimeTapped):
        state.favoritePrimes.removeAll(where: { $0 == state.count })
        state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(state.count)))
    default:
        break
    }
}

func favoritePrimesReducer(state: inout FavoritePrimesState, action: AppAction) -> Void {
    
    switch action {
    case let .favoritePrimes(.deleteFavoritePrimes(indexSet)):
        for index in indexSet {
            let prime = state.favoritePrimes[index]
            state.favoritePrimes.remove(at: index)
            state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
        }
    default:
        break
    }
}
