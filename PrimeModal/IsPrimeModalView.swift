//
//  IsPrimeModalView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core

public struct IsPrimeModalView: View {
    
    @ObservedObject var store: Store<PrimeModalState, PrimeModalAction>
    
    public init(store: Store<PrimeModalState, PrimeModalAction>) {
        
        self.store = store
    }
    
    public var body: some View {
        VStack {
            if self.isPrime(self.store.value.count) {
                Text("\(self.store.value.count) is prime 🎉")
                if self.store.value.favoritePrimes.contains(self.store.value.count) {
                    Button(action: {
                        
                        self.store.send(.removeFavoritePrimeTapped)
                    }) {
                        Text("Remove from favorite primes")
                    }
                } else {
                    Button(action: {
                        
                        self.store.send(.saveFavoritePrimeTapped)
                    }) {
                        Text("Save to favorite primes")
                    }
                }
                
            } else {
                Text("\(self.store.value.count) is not prime :(")
            }
        }
    }
    
    private func isPrime (_ p: Int) -> Bool {
        if p <= 1 { return false }
        if p <= 3 { return true }
        for i in 2...Int(sqrtf(Float(p))) {
            if p % i == 0 { return false }
        }
        return true
    }
    
    private func isPrimeEffect(_ p: Int) -> Effect<Bool> {
        return Effect<Bool> { closure in
            if p <= 1 {
                closure(false)
                return
            }
            if p <= 3 {
                closure(true)
                return
            }
            for i in 2...Int(sqrtf(Float(p))) {
                if p % i == 0 {
                    closure(false)
                    return
                }
            }
            closure(true)
        }
        .run(on: .global())
        .receive(on: .main)
    }
}

struct IsPrimeModalView_Previews: PreviewProvider {
    static var previews: some View {
        IsPrimeModalView(
            store: Store(initialValue: PrimeModalState(count: 0, favoritePrimes: [0]), reducer: primeModalReducer)
        )
    }
}
