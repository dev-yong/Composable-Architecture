//
//  CounterView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core
import PrimeModal

struct PrimeAlert: Identifiable {
  let prime: Int

  var id: Int { self.prime }
}

public typealias CounterViewState = (count: Int, favoritePrimes: [Int])
public enum CounterViewAction {
    
  case counter(CounterAction)
  case primeModal(PrimeModalAction)
}

public struct CounterView: View {
    
    // MARK: AppState
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    
    public init(store: Store<CounterViewState, CounterViewAction>) {
        
        self.store = store
    }
    
    // MARK: Local State
    @State var isPrimeModalShown = false
    @State var alertNthPrime: PrimeAlert?
    @State var isNthPrimeButtonDisabled = false
    
    // MARK: Body
    public var body: some View {
      VStack {
        HStack {
            Button(action: {
                self.store.send(.counter(.decrTapped))
            }) {
                Text("-")
            }
            Text("\(self.store.value.count)")
            Button(action: {
                self.store.send(.counter(.incrTapped))
            }) {
                Text("+")
            }
        }
        Button(action: { self.isPrimeModalShown = true }) {
            Text("Is this prime?")
        }
        Button(action: self.nthPrimeButtonAction) {
            Text("What is the \(ordinal(self.store.value.count)) prime?")
        }.disabled(isNthPrimeButtonDisabled)
      }
      .font(.title)
      .navigationBarTitle("Counter demo")
      .sheet(isPresented: self.$isPrimeModalShown) {
        IsPrimeModalView(
            store: self.store.view(
                value: { PrimeModalState(count: $0.count, favoritePrimes: $0.favoritePrimes) },
                action: { .primeModal($0) }
            )
        )
      }
      .alert(item: self.$alertNthPrime) { alert in
        Alert(
          title: Text(
            "The \(ordinal(self.store.value.count)) prime is \(alert.prime)"
          ),
          dismissButton: .default(Text("Ok"))
        )
      }
    }
    
    private func ordinal(_ n: Int) -> String {
      let formatter = NumberFormatter()
      formatter.numberStyle = .ordinal
      return formatter.string(for: n) ?? ""
    }
    
    private func nthPrimeButtonAction() {
    
      self.isNthPrimeButtonDisabled = true
      nthPrime(self.store.value.count) { prime in
        self.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        self.isNthPrimeButtonDisabled = false
      }
    }
}

//struct CounterView_Previews: PreviewProvider {
//    static var previews: some View {
//        CounterView(store: Store<CounterViewState, CounterViewAction>(initialValue: (0, [0]), reducer: { (state, action) in
//
//            switch action {
//
//            case.counter(let action):
//                counterReducer(state: &state.count, action: action)
//            case .primeModal(let action):
//
//                primeModalReducer(state: PrimeModalState(count: state.count, favoritePrimes: state.favoritePrimes), action: action)
//            }
//        }))
//    }
//}
//
