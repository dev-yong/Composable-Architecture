//
//  CounterView.swift
//  CombosableArchitecture
//
//  Created by 이광용 on 2020/09/21.
//

import SwiftUI
import Core
import PrimeModal

public struct PrimeAlert: Equatable, Identifiable {
    let prime: Int
    
    public var id: Int { self.prime }
}

public struct CounterViewState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var count: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeButtonDisabled: Bool
    
    public init(
        alertNthPrime: PrimeAlert? = nil,
        count: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeButtonDisabled: Bool = false
    ) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeButtonDisabled = isNthPrimeButtonDisabled
    }
    
    var counter: CounterState {
        get {
            (self.alertNthPrime, self.count, self.isNthPrimeButtonDisabled)
        }
        set {
            (self.alertNthPrime, self.count, self.isNthPrimeButtonDisabled) = newValue
        }
    }
    
    var primeModal: PrimeModalState {
        get {
            (self.count, self.favoritePrimes)
        }
        set {
            (self.count, self.favoritePrimes) = newValue
        }
    }
}

public enum CounterViewAction: Equatable {
    
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
    pullback(counterReducer, value: \CounterViewState.counter, action: \CounterViewAction.counter),
    pullback(primeModalReducer, value: \.primeModal, action: \.primeModal)
)


public struct CounterView: View {
    
    // MARK: AppState
    @ObservedObject var store: Store<CounterViewState, CounterViewAction>
    
    public init(store: Store<CounterViewState, CounterViewAction>) {
        
        self.store = store
    }
    
    // MARK: Local State
    @State var isPrimeModalShown = false
    
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
            }.disabled(self.store.value.isNthPrimeButtonDisabled)
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
        .alert(
            item: .constant(self.store.value.alertNthPrime)
        ) { alert in
            Alert(
                title: Text(
                    "The \(ordinal(self.store.value.count)) prime is \(alert.prime)"
                ),
                dismissButton: .default(
                    Text("OK"),
                    action: {
                        self.store.send(.counter(.alertDismissButtonTapped))
                    }
                )
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
                initialValue: CounterViewState(
                    count: 0,
                    favoritePrimes: []
                ),
                reducer: counterViewReducer
            )
        )
    }
}

