//
//  Store.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation

final class Store<Value, Action>: ObservableObject {
    
    let reducer: (Value, Action) -> Value
    @Published var value: Value
    
    init(
        initialValue: Value,
        reducer: @escaping (Value, Action) -> Value
    ) {
        self.value = initialValue
        self.reducer = reducer
    }
    
    func send(_ action: Action) {
        self.value = self.reducer(self.value, action)
    }
}
