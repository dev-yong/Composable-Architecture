//
//  FavoritePrimesView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI

class FavoritePrimeState: ObservableObject {
    
    private var state: AppState
    init(state: AppState) {
        
        self.state = state
    }
    
    var favoritePrimes: [Int] {
        get { self.state.favoritePrimes }
        set { self.state.favoritePrimes = newValue }
    }
    var activityFeed: [Activity] {
        get { self.state.activityFeed }
        set { self.state.activityFeed = newValue }
    }
}

struct FavoritePrimesView: View {
    
    @ObservedObject var state: FavoritePrimeState
    
    var body: some View {
        List {
          ForEach(self.state.favoritePrimes, id: \.self) { prime in
            Text("\(prime)")
          }
          .onDelete { indexSet in
            
            for index in indexSet {
              let prime = self.state.favoritePrimes[index]
              self.state.favoritePrimes.remove(at: index)
              self.state.activityFeed.append(.init(timestamp: Date(), type: .removedFavoritePrime(prime)))
            }
          }
        }
          .navigationBarTitle(Text("Favorite Primes"))
    }
}

struct FavoritePrimesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritePrimesView(
            state: FavoritePrimeState(state: AppState())
        )
    }
}
