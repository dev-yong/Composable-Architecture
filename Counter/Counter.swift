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
}

public typealias CounterState = (
    alertNthPrime: PrimeAlert?,
    count: Int,
    isNthPrimeButtonDisabled: Bool
)

struct CounterEnvironment {
    var nthPrime: (Int) -> Effect<Int?>
}
extension CounterEnvironment {
    
    static let live = CounterEnvironment(nthPrime: Counter.nthPrime)
    #if DEBUG
    static let mock = CounterEnvironment(nthPrime: { _ in .sync { 17 } })
    #endif
}

var Current = CounterEnvironment.live

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
            Current.nthPrime(count)
                .map { .nthPrimeResponse($0) }
                .receive(on: DispatchQueue.main)
                .eraseToEffect()
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

