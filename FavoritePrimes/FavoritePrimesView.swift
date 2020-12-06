//
//  FavoritePrimesView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core

public struct FavoritePrimesView: View {
    
    @ObservedObject var store: Store<[Int], FavoritePrimesAction>
    
    public init(store: Store<[Int], FavoritePrimesAction>) {
        
        self.store = store
    }
    
    public var body: some View {
        List {
            ForEach(self.store.value, id: \.self) { prime in
                Text("\(prime)")
            }
            .onDelete { indexSet in
                
                self.store.send(.deleteFavoritePrimes(indexSet))
            }
        }
        .navigationBarTitle(Text("Favorite Primes"))
        .navigationBarItems(
            trailing: HStack {
                Button("Save") {
                    self.store.send(.saveButtonTapped)
                }
                Button("Load") {
                    let documentsPath = NSSearchPathForDirectoriesInDomains(
                        .documentDirectory, .userDomainMask, true
                    )[0]
                    let documentsUrl = URL(fileURLWithPath: documentsPath)
                    let favoritePrimesUrl = documentsUrl
                        .appendingPathComponent("favorite-primes.json")
                    guard
                        let data = try? Data(contentsOf: favoritePrimesUrl),
                        let favoritePrimes = try? JSONDecoder().decode([Int].self, from: data)
                    else { return }
                    self.store.send(.loadedFavoritePrimes(favoritePrimes))
                }
                
            }
        )
    }
}

struct FavoritePrimesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritePrimesView(
            store: Store(initialValue: [0], reducer: favoritePrimesReducer)
        )
    }
}
