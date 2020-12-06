//
//  Core.swift
//  Core
//
//  Created by 이광용 on 2020/11/02.
//

import Combine
import SwiftUI

public typealias Reducer<Value, Action> = (inout Value, Action) -> Void

public final class Store<Value, Action>: ObservableObject {
    
    public let reducer: Reducer<Value, Action>
    @Published
    public private(set) var value: Value
    private var cancellableBag = Set<AnyCancellable>()
    
    public init(
        initialValue: Value,
        reducer: @escaping Reducer<Value, Action>
    ) {
        
        self.value = initialValue
        self.reducer = reducer
    }
    
    public func send(_ action: Action) {
        self.reducer(&self.value, action)
    }
    
    public func view<LocalValue, LocalAction>(
        value toLocalValue: @escaping (Value) -> LocalValue,
        action toLocalAction: @escaping (LocalAction) -> Action
    ) -> Store<LocalValue, LocalAction> {
        
        let localStore = Store<LocalValue, LocalAction>(
            initialValue: toLocalValue(self.value),
            reducer: { localValue, localAction in
                self.send(toLocalAction(localAction))
                localValue = toLocalValue(self.value)
            }
        )
        self.cancellableBag.insert(
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
            }
        )
        self.cancellableBag.insert(
            self.$value.sink { [weak localStore] (newValue) in
                localStore?.value = f(newValue)
            }
        )
        return localStore
    }
}

public func combine<Value, Action>(
    _ first: @escaping Reducer<Value, Action>,
    _ second: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
    
    return { value, action in
        first(&value, action)
        second(&value, action)
    }
}

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    
    return { value, action in
        for reducer in reducers {
            reducer(&value, action)
        }
    }
}

public func pullback<LocalValue, GlobalValue, Action>(
    _ reducer: @escaping Reducer<LocalValue, Action>,
    value: WritableKeyPath<GlobalValue, LocalValue>
) -> Reducer<GlobalValue, Action> {
    
    return { globalValue, action in
        reducer(&globalValue[keyPath: value], action)
    }
}

public func pullback<Value, GlobalAction, LocalAction>(
    _ reducer: @escaping Reducer<Value, LocalAction>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<Value, GlobalAction> {
    
    return { value, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&value, localAction)
    }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return }
        reducer(&globalValue[keyPath: value], localAction)
    }
}

public func logging<Value, Action>(
    _ reducer: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
    
    return { value, action in
        reducer(&value, action)
        print("Action: \(action)")
        print("value:")
        dump(value)
        print("---")
    }
}

public func transform<A, B, Action>(
    _ reducer: (inout A, Action) -> Void,
    _ f: (A) -> B
) -> (inout B, Action) -> Void {
    fatalError()
}
