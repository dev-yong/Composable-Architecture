//
//  Pullback.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/11.
//

import Foundation

func pullback<LocalValue, GlobalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>
) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        reducer(&globalValue[keyPath: value], action)
    }
}
