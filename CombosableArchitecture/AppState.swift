//
//  AppState.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Counter
import PrimeModal

struct AppState {
    
    var count = 0
    var favoritePrimes: [Int] = []
    var loggedInUser: User?
    var activityFeed: [Activity] = []
    var alertNthPrime: PrimeAlert? = nil
    var isNthPrimeButtonDisabled: Bool = false
    
    struct User {
        
        let id: Int
        let name: String
        let bio: String
    }
    
    struct Activity {
        let timestamp: Date
        let type: ActivityType
        
        enum ActivityType {
            case addedFavoritePrime(Int)
            case removedFavoritePrime(Int)
        }
    }
}

extension AppState {
    
    var counter: CounterState {
        get {
            (alertNthPrime, count, isNthPrimeButtonDisabled)
        }
        set{
            self.alertNthPrime = newValue.alertNthPrime
            self.count = newValue.count
            self.isNthPrimeButtonDisabled = newValue.isNthPrimeButtonDisabled
        }
    }
    
    var counterView: CounterViewState {
        get {
            CounterViewState(
                alertNthPrime: self.alertNthPrime,
                count: self.count,
                favoritePrimes: self.favoritePrimes,
                isNthPrimeButtonDisabled: self.isNthPrimeButtonDisabled
            )
        }
        set {
            self.alertNthPrime = newValue.alertNthPrime
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
            self.isNthPrimeButtonDisabled = newValue.isNthPrimeButtonDisabled
        }
    }
    var primeModal: PrimeModalState {
        get {
            PrimeModalState(
                count: self.count,
                favoritePrimes: self.favoritePrimes
            )
        }
        set {
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
        }
    }
    
}
