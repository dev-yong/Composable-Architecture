//
//  Pullback.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/11.
//

import Foundation

func pullback<LocalValue, GlobalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    get: @escaping (GlobalValue) -> LocalValue,
    set: @escaping (inout GlobalValue, LocalValue) -> Void
) -> (inout GlobalValue, Action) -> Void {
    
    return  { globalValue, action in
        var localValue = get(globalValue)
        reducer(&localValue, action)
        set(&globalValue, localValue)
    }
}
