//
//  Store.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Combine

public final class Store<Value, Action>: ObservableObject {
    
    public let reducer: Reducer<Value, Action, Any>
    private let environment: Any
    @Published
    public private(set) var value: Value
    
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
    
    private var viewCancellableBag = Set<AnyCancellable>()
    public func view<LocalValue, LocalAction>(
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
        self.viewCancellableBag.insert(
            self.$value.sink { [weak localStore] (newValue) in
                localStore?.value = toLocalValue(newValue)
            }
        )
        return localStore
    }
    
}
