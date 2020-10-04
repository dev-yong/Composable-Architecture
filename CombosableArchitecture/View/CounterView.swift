//
//  CounterView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI

struct PrimeAlert: Identifiable {
  let prime: Int

  var id: Int { self.prime }
}

struct CounterView: View {
    
    // MARK: AppState
    @ObservedObject var store: Store<AppState, AppAction>
    
    // MARK: Local State
    @State var isPrimeModalShown = false
    @State var alertNthPrime: PrimeAlert?
    @State var isNthPrimeButtonDisabled = false
    
    // MARK: Body
    var body: some View {
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
        IsPrimeModalView(store: self.store)
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

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView(
            store: Store(initialValue: AppState(), reducer: appReducer)
        )
    }
}
