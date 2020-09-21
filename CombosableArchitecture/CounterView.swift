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
    @ObservedObject var state: AppState
    
    // MARK: Local State
    @State var isPrimeModalShown = false
    @State var alertNthPrime: PrimeAlert?
    @State var isNthPrimeButtonDisabled = false
    
    // MARK: Body
    var body: some View {
      VStack {
        HStack {
          Button(action: { self.state.count -= 1 }) {
            Text("-")
          }
          Text("\(self.state.count)")
          Button(action: { self.state.count += 1 }) {
            Text("+")
          }
        }
        Button(action: { self.isPrimeModalShown = true }) {
          Text("Is this prime?")
        }
        Button(action: self.nthPrimeButtonAction) {
          Text("What is the \(ordinal(self.state.count)) prime?")
        }.disabled(isNthPrimeButtonDisabled)
      }
      .font(.title)
      .navigationBarTitle("Counter demo")
      .sheet(isPresented: self.$isPrimeModalShown) {
        IsPrimeModalView(state: self.state)
      }
      .alert(item: self.$alertNthPrime) { alert in
        Alert(
          title: Text(
            "The \(ordinal(self.state.count)) prime is \(alert.prime)"
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
      nthPrime(self.state.count) { prime in
        self.alertNthPrime = prime.map(PrimeAlert.init(prime:))
        self.isNthPrimeButtonDisabled = false
      }
    }
}

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView(
            state: AppState()
        )
    }
}
