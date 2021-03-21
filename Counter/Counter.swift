//
//  Counter.swift
//  Counter
//
//  Created by 이광용 on 2020/11/08.
//

import Foundation
import Core

public enum CounterAction: Equatable {
    
    case decrTapped
    case incrTapped
    case nthPrimeButtonTapped
    case nthPrimeResponse(Int?)
    case alertDismissButtonTapped
    case isPrimeButtonTapped
    case primeModalDismissed
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    count: Int,
    isNthPrimeRequestInFlight: Bool,
    isPrimeModalShown: Bool
)

public typealias CounterEnvironment = (Int) -> Effect<Int?>

public func counterReducer(
    state: inout CounterState,
    action: CounterAction,
    environment: CounterEnvironment
) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state.count -= 1
        return []
    case .incrTapped:
        state.count += 1
        return []
    case .nthPrimeButtonTapped:
        state.isNthPrimeRequestInFlight = true
        let count = state.count
        return [
            environment(count)
                .map { .nthPrimeResponse($0) }
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
        ]
    case .alertDismissButtonTapped:
        state.alertNthPrime = nil
        return []
    case .nthPrimeResponse(let prime):
        state.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        state.isNthPrimeRequestInFlight = false
        return []
    case .isPrimeButtonTapped:
        state.isPrimeModalShown = true
        return []
    case .primeModalDismissed:
      state.isPrimeModalShown = false
      return []
    }
}

