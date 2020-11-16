//
//  ContentView_66.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core

struct ContentView: View {
    @ObservedObject var store: Store<AppState, AppAction>

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: CounterView(
                        store:  self.store.view(
                            value: { ($0.count, $0.favoritePrimes) },
                            action: { $0 }
                        )
                    )
                ) {
                    Text("Counter demo")
                }
                NavigationLink(
                    destination: FavoritePrimesView(
                        store: self.store.view(
                        value: { $0.favoritePrimes },
                        action: { .favoritePrimes($0) }
                      )
                    )
                ) {
                    Text("Favorite primes")
                }
            }
            .navigationBarTitle("State management")
        }
    }
}

struct ContentView_66_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            store: Store(initialValue: AppState(), reducer: appReducer)
        )
    }
}
