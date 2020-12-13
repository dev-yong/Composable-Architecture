//
//  CounterView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core
import PrimeModal

public struct PrimeAlert: Identifiable {
  let prime: Int

  public var id: Int { self.prime }
}

public typealias CounterViewState = (
  alertNthPrime: PrimeAlert?,
  count: Int,
  favoritePrimes: [Int],
  isNthPrimeButtonDisabled: Bool
)

public enum CounterViewAction {
    
    case counter(CounterAction)
    case primeModal(PrimeModalAction)
    
    var counter: CounterAction? {
        get {
            guard case let .counter(value) = self else { return nil }
            return value
        }
        set {
            guard case .counter = self, let newValue = newValue else { return }
            self = .counter(newValue)
        }
    }
    
    var primeModal: PrimeModalAction? {
        get {
            guard case let .primeModal(value) = self else { return nil }
            return value
        }
        set {
            guard case .primeModal = self, let newValue = newValue else { return }
            self = .primeModal(newValue)
        }
    }
}
public let counterViewReducer = combine(
    pullback(counterReducer, value: \CounterViewState.count, action: \CounterViewAction.counter),
    pullback(primeModalReducer, value: \.self, action: \.primeModal)
)


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
    
        self.store.send(.counter(.nthPrimeButtonTapped))
    }
}

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView(
            store: Store<CounterViewState, CounterViewAction>(
                initialValue: (0, [0]),
                reducer: counterViewReducer
            )
        )
    }
}

