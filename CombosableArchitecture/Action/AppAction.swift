//
//  AppAction.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation
import Counter
import PrimeModal
import FavoritePrimes

enum AppAction {
    
    case counterView(CounterViewAction)
    case favoritePrimes(FavoritePrimesAction)
    
    var counterView: CounterViewAction? {
        get {
            guard case let .counterView(value) = self else { return nil }
            return value
        }
        set {
            guard case .counterView = self, let newValue = newValue else { return }
            self = .counterView(newValue)
        }
    }
    
    var favoritePrimes: FavoritePrimesAction? {
        get {
            guard case let .favoritePrimes(value) = self else { return nil }
            return value
        }
        set {
            guard case .favoritePrimes = self, let newValue = newValue else { return }
            self = .favoritePrimes(newValue)
        }
    }
    
}
