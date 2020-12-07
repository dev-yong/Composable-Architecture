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
}

public func counterReducer(state: inout Int, action: CounterAction) -> [Effect<CounterAction>] {
    switch action {
    case .decrTapped:
        state -= 1
        return []
    case .incrTapped:
        state += 1
        return []
    }
}

