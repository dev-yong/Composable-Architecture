//
//  Counter.swift
//  Counter
//
//  Created by 이광용 on 2020/11/08.
//

import Foundation
import Core

public enum CounterAction {
    
    case decrTapped
    case incrTapped
    case nthPrimeButtonTapped
}

public func counterReducer(state: inout Int, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state -= 1
        return []
    case .incrTapped:
        state += 1
        return []
    case .nthPrimeButtonTapped
        return [{
             // counterReducer에게 더 많은 state를 알 수 있도록 해야한다.
//            self.isNthPrimeButtonDisabled = true
//            nthPrime(self.store.value.count) { prime in
//                self.alertNthPrime = prime.map(PrimeAlert.init(prime:))
//                self.isNthPrimeButtonDisabled = false
//            }
        }]
    }
}

