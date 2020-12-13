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
    case nthPrimeResponse(Int?)
    case alertDismissButtonTapped
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    count: Int,
    isNthPrimeButtonDisabled: Bool
)

public func counterReducer(state: inout CounterState, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state.count -= 1
        return []
    case .incrTapped:
        state.count += 1
        return []
    case .nthPrimeButtonTapped:
        state.isNthPrimeButtonDisabled = true
        let count = state.count
        return [
            Effect<Int?>(
                run: { callback in
                    nthPrime(count) { prime in
                        DispatchQueue.main.async {
                            callback(prime)
                        }
                    }
                }
            ).map { .nthPrimeResponse($0) }
        ]
    case .alertDismissButtonTapped:
        state.alertNthPrime = nil
        return []
    case .nthPrimeResponse(let prime):
        state.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        state.isNthPrimeButtonDisabled = false
        return []
    }
}

