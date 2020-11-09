//
//  FavoritePrimesView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core

struct FavoritePrimesView: View {
    
    @ObservedObject var store: Store<[Int], AppAction>
    
    var body: some View {
        List {
            ForEach(self.store.value, id: \.self) { prime in
            Text("\(prime)")
          }
          .onDelete { indexSet in
            
            self.store.send(.favoritePrimes(.deleteFavoritePrimes(indexSet)))
          }
        }
          .navigationBarTitle(Text("Favorite Primes"))
    }
}

struct FavoritePrimesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritePrimesView(
            store: Store(initialValue: AppState(), reducer: appReducer)
                .view { $0.favoritePrimes }
        )
    }
}
