//
//  CounterAction.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation

enum CounterAction {
    
    case decrTapped
    case incrTapped
}

/// `reduce` 에서 영감을 받아 `Reducer`라고 명명하였다.
func counterReducer(state: AppState, action: CounterAction) -> AppState {
    
    var copy = state
    switch action {
    case .decrTapped:
       copy.count -= 1
     case .incrTapped:
       copy.count += 1
     }
    return copy
}
