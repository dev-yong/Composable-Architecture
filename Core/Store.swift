//
//  Store.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Combine

public final class Store<Value, Action> {
    
    public let reducer: Reducer<Value, Action, Any>
    private let environment: Any
    @Published
    private var value: Value
    
    public init<Environment>(
        initialValue: Value,
        reducer: @escaping Reducer<Value, Action, Environment>,
        environment: Environment
    ) {
        
        self.value = initialValue
        self.reducer = { value, action, environment in
            reducer(&value, action, environment as! Environment)
          }
        self.environment = environment
    }
    
    private var effectCancellableBag = Set<AnyCancellable>()
    public func send(_ action: Action) {
        let effects = self.reducer(&self.value, action, self.environment)
        effects.forEach {
            var effectCancellable: AnyCancellable?
            var didComplete = false
            effectCancellable = $0.sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    guard let effectCancellable = effectCancellable else { return }
                    self?.effectCancellableBag.remove(effectCancellable)
                },
                receiveValue: { [weak self] in self?.send($0) }
            )
            if !didComplete,
               let effectCancellable = effectCancellable {
                self.effectCancellableBag.insert(effectCancellable)
            }
        }
    }
    
    private var scopeCancellableBag = Set<AnyCancellable>()
    public func scope<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toGlobalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(self.value),
            reducer: { localValue, localAction, _ in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            },
            environment: self.environment
        )
        localStore.scopeCancellableBag.insert(
            self.$value
                .map(toLocalValue)
//                .removeDuplicates()
                .sink { [weak localStore] newValue in localStore?.value = newValue }
        )
        return localStore
    }
    
}


public final class ViewStore<Value>: ObservableObject {
    
    @Published
    public fileprivate(set) var value: Value
    fileprivate var cancellable: Cancellable?

    init(
        initialValue: Value
    ) {
        self.value = initialValue
    }
}

extension Store {

    public func view(
        removeDuplicates predicate: @escaping (Value, Value) -> Bool
    ) -> ViewStore<Value> {
        let viewStore = ViewStore(initialValue: self.value)
        viewStore.cancellable = self.$value
            .removeDuplicates(by: predicate)
            .sink { [weak viewStore] newValue in viewStore?.value = newValue }
        return viewStore
    }

}

extension Store where Value: Equatable {
    
    public var view: ViewStore<Value> {
        self.view(removeDuplicates: ==)
    }
    
}
