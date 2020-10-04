//
//  Store.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/10/04.
//

import Foundation

final class Store: ObservableObject {
    
    @Published var value: AppState
    
    init(initialValue: AppState) {
        
        self.value = initialValue
    }
}
