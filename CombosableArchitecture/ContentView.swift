//
//  ContentView_66.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState

    var body: some View {
        NavigationView {
            List {
                NavigationLink(
                    destination: CounterView(state: self.state)
                ) {
                    Text("Counter demo")
                }
                NavigationLink(
                    destination: FavoritePrimesView(state: FavoritePrimeState(state: self.state))
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
            state: AppState()
        )
    }
}
