//
//  Store.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Combine

public final class Store<Value, Action>: ObservableObject {
    
    public let reducer: Reducer<Value, Action>
    @Published
    public private(set) var value: Value
    
    public init(
        initialValue: Value,
        reducer: @escaping Reducer<Value, Action>
    ) {
        
        self.value = initialValue
        self.reducer = reducer
    }
    
    private var effectCancellableBag = Set<AnyCancellable>()
    public func send(_ action: Action) {
        let effects = self.reducer(&self.value, action)
        effects.forEach {
            var effectCancellable: AnyCancellable?
            var didComplete = false
            effectCancellable = $0.sink(
                receiveCompletion: { [weak self] _ in
                    didComplete = true
                    guard let effectCancellable = effectCancellable else { return }
                    self?.effectCancellableBag.remove(effectCancellable)
                },
                receiveValue: self.send
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
            reducer: { localValue, localAction in
                self.send(toGlobalAction(localAction))
                localValue = toLocalValue(self.value)
                return []
            }
        )
        self.viewCancellableBag.insert(
            self.$value.sink { [weak localStore] (newValue) in
                localStore?.value = toLocalValue(newValue)
            }
        )
        return localStore
    }
    
    public func view<LocalAction>(
        _ f: @escaping (LocalAction) -> Action
    ) -> Store<Value, LocalAction> {
        
        return Store<Value, LocalAction>(
            initialValue: self.value) { (value, localAction) in
            
            self.send(f(localAction))
            value = self.value
            return []
        }
    }
    
    public func view<LocalValue>(
        _ f: @escaping (Value) -> LocalValue
    ) -> Store<LocalValue, Action> {
        let localStore = Store<LocalValue, Action>(
            initialValue: f(self.value),
            reducer: { localValue, action in
                self.send(action)
                localValue = f(self.value)
                return []
            }
        )
        self.viewCancellableBag.insert(
            self.$value.sink { [weak localStore] (newValue) in
                localStore?.value = f(newValue)
            }
        )
        return localStore
    }
    
}
