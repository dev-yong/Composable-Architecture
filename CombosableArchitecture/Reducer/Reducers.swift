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
  _ reducer: @escaping Reducer<AppState, AppAction, AppEnvironment>
) -> Reducer<AppState, AppAction, AppEnvironment> {

    return { state, action, environment in
        
        switch action {
        
        
        // activity feed에 중요하지 않다.
        case .counterView,
             .favoritePrimes(.loadedFavoritePrimes),
             .favoritePrimes(.saveButtonTapped),
             .favoritePrimes(.loadButtonTapped):
            break
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
        return reducer(&state, action, environment)
    }
}

struct AppEnvironment {
    var counter: CounterEnvironment
    var favoritePrimes: FavoritePrimesEnvironment
}

extension AppEnvironment {
    
    static var live = AppEnvironment(counter: .live, favoritePrimes: .live)
    #if DEBUG
    static var mock = AppEnvironment(counter: .mock, favoritePrimes: .mock)
    #endif
}

let appReducer: Reducer<AppState, AppAction, AppEnvironment> = combine(
  pullback(
    counterViewReducer,
    value: \AppState.counterView,
    action: \AppAction.counterView,
    environemnt: { $0.counter }
  ),
  pullback(
    favoritePrimesReducer,
    value: \.favoritePrimes,
    action: \.favoritePrimes,
    environemnt: { $0.favoritePrimes }
  )
)
