//
//  Store.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation

final class Store<Value, Action>: ObservableObject {
    
    let reducer: (inout Value, Action) -> Void
    @Published var value: Value
    
    init(
        initialValue: Value,
        reducer: @escaping (inout Value, Action) -> Void
    ) {
        self.value = initialValue
        self.reducer = reducer
    }
    
    func send(_ action: Action) {
        self.reducer(&self.value, action)
    }
}
