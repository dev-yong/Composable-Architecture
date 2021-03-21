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
    var isNthPrimeRequestInFlight: Bool = false
    var isPrimeModalShown: Bool = false
    
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
            (alertNthPrime, count, isNthPrimeRequestInFlight, isPrimeModalShown)
        }
        set{
            self.alertNthPrime = newValue.alertNthPrime
            self.count = newValue.count
            self.isNthPrimeRequestInFlight = newValue.isNthPrimeRequestInFlight
            self.isPrimeModalShown = newValue.isPrimeModalShown
        }
    }
    
    var counterView: CounterFeatureState {
        get {
            CounterFeatureState(
                alertNthPrime: self.alertNthPrime,
                count: self.count,
                favoritePrimes: self.favoritePrimes,
                isNthPrimeRequestInFlight: self.isNthPrimeRequestInFlight,
                isPrimeModalShown: self.isPrimeModalShown
            )
        }
        set {
            self.alertNthPrime = newValue.alertNthPrime
            self.count = newValue.count
            self.favoritePrimes = newValue.favoritePrimes
            self.isNthPrimeRequestInFlight = newValue.isNthPrimeRequestInFlight
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
