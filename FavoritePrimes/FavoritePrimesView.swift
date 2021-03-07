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
                    self.store.send(.loadButtonTapped)
                }
                
            }
        )
    }
}

struct FavoritePrimesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritePrimesView(
                store: Store(
                    initialValue: [2, 3, 5, 7],
                    reducer: favoritePrimesReducer,
                    environment: FavoritePrimesEnvironment.mock
                )
            )
        }
    }
}
