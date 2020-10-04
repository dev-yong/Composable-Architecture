//
//  Store.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation

final class Store<Value>: ObservableObject {
    
    @Published var value: Value
    
    init(initialValue: Value) {
        
        self.value = initialValue
    }
}
