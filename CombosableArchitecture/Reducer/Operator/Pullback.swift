//
//  Pullback.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/11.
//

import Foundation

func pullback<LocalValue, GlobalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    _ f: @escaping (inout GlobalValue) -> LocalValue
) -> (inout GlobalValue, Action) -> Void {
    
    return { globalValue, action in
        
        var localValue = f(&globalValue)
        reducer(&localValue, action)
    }
}
