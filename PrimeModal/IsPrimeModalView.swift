//
//  IsPrimeModalView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core

public struct IsPrimeModalView: View {
    
    struct State: Equatable {
        let count: Int
        let isFavorite: Bool
        
        init(primeModalState state: PrimeModalState) {
          self.count = state.count
          self.isFavorite = state.favoritePrimes.contains(state.count)
        }
    }
    
    let store: Store<PrimeModalState, PrimeModalAction>
    @ObservedObject var viewStore: ViewStore<State>
    
    public init(store: Store<PrimeModalState, PrimeModalAction>) {
        
        self.store = store
        self.viewStore = store.scope(
            value: { State(primeModalState: $0) },
            action: { $0 }
        ).view
    }
    
    public var body: some View {
        VStack {
            if self.isPrime(self.viewStore.value.count) {
                Text("\(self.viewStore.value.count) is prime 🎉")
                if self.viewStore.value.isFavorite {
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
                Text("\(self.viewStore.value.count) is not prime :(")
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
}

struct IsPrimeModalView_Previews: PreviewProvider {
    static var previews: some View {
        IsPrimeModalView(
            store: Store(
                initialValue: PrimeModalState(count: 0, favoritePrimes: [0]),
                reducer: primeModalReducer,
                environment: Void()
            )
        )
    }
}
