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

public struct CounterFeatureState: Equatable {
    public var alertNthPrime: PrimeAlert?
    public var count: Int
    public var favoritePrimes: [Int]
    public var isNthPrimeRequestInFlight: Bool
    public var isPrimeModalShown: Bool
    
    public init(
        alertNthPrime: PrimeAlert? = nil,
        count: Int = 0,
        favoritePrimes: [Int] = [],
        isNthPrimeRequestInFlight: Bool = false,
        isPrimeModalShown: Bool = false
    ) {
        self.alertNthPrime = alertNthPrime
        self.count = count
        self.favoritePrimes = favoritePrimes
        self.isNthPrimeRequestInFlight = isNthPrimeRequestInFlight
        self.isPrimeModalShown = isPrimeModalShown
    }
    
    var counter: CounterState {
        get {
            (self.alertNthPrime, self.count, self.isNthPrimeRequestInFlight, self.isPrimeModalShown)
        }
        set {
            (self.alertNthPrime, self.count, self.isNthPrimeRequestInFlight, self.isPrimeModalShown) = newValue
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

public enum CounterFeatureAction: Equatable {
    
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
public let counterViewReducer: Reducer<CounterFeatureState, CounterFeatureAction, CounterEnvironment> = combine(
    pullback(
        counterReducer,
        value: \CounterFeatureState.counter,
        action: \CounterFeatureAction.counter,
        environemnt: { $0 }
    ),
    pullback(
        primeModalReducer,
        value: \.primeModal,
        action: \.primeModal,
        environemnt: { _ in Void() }
    )
)

public struct CounterView: View {
    
    struct State: Equatable {
        let alertNthPrime: PrimeAlert?
        let count: Int
        let isNthPrimeButtonDisabled: Bool
        let isPrimeModalShown: Bool
        
        init(
            counterFeatureState: CounterFeatureState
        ) {
            self.alertNthPrime = counterFeatureState.alertNthPrime
            self.count = counterFeatureState.count
            self.isNthPrimeButtonDisabled = counterFeatureState.isNthPrimeRequestInFlight
            self.isPrimeModalShown = counterFeatureState.isPrimeModalShown
        }
    }
    
    // MARK: AppState
    let store: Store<CounterFeatureState, CounterFeatureAction>
    @ObservedObject var viewStore: ViewStore<State>
    
    public init(store: Store<CounterFeatureState, CounterFeatureAction>) {
        
        self.store = store
        self.viewStore = store.scope(
            value: { CounterView.State(counterFeatureState: $0) },
            action: { $0 }
        ).view
    }
    
    // MARK: Body
    public var body: some View {
        VStack {
            HStack {
                Button(action: {
                    self.store.send(.counter(.decrTapped))
                }) {
                    Text("-")
                }
                Text("\(self.viewStore.value.count)")
                Button(action: {
                    self.store.send(.counter(.incrTapped))
                }) {
                    Text("+")
                }
            }
            Button(action: { self.store.send(.counter(.isPrimeButtonTapped)) }) {
                Text("Is this prime?")
            }
            Button(action: { self.store.send(.counter(.nthPrimeButtonTapped)) }) {
                Text("What is the \(ordinal(self.viewStore.value.count)) prime?")
            }.disabled(self.viewStore.value.isNthPrimeButtonDisabled)
        }
        .font(.title)
        .navigationBarTitle("Counter demo")
        .sheet(
          isPresented: .constant(self.viewStore.value.isPrimeModalShown),
          onDismiss: { self.store.send(.counter(.primeModalDismissed)) }
        ) {
            IsPrimeModalView(
                store: self.store.scope(
                    value: { PrimeModalState(count: $0.count, favoritePrimes: $0.favoritePrimes) },
                    action: { .primeModal($0) }
                )
            )
        }
        .alert(
            item: .constant(self.viewStore.value.alertNthPrime)
        ) { alert in
            Alert(
                title: Text(
                    "The \(ordinal(self.viewStore.value.count)) prime is \(alert.prime)"
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
            store: Store<CounterFeatureState, CounterFeatureAction>(
                initialValue: CounterFeatureState(
                    count: 0,
                    favoritePrimes: []
                ),
                reducer: counterViewReducer,
                environment: { _ in .sync { 17 } }
            )
        )
    }
}

