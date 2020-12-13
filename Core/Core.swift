//
//  Core.swift
//  Core
//
//  Created by 이광용 on 2020/11/02.
//

import Combine
import SwiftUI

public struct Effect<Action> {
    
    public let run: (@escaping (Action) -> Void) -> Void
    public init(
        run: @escaping (@escaping (Action) -> Void) -> Void
    ) {
        self.run = run
    }
    
    public func map<T>(
        _ transform: @escaping (Action) -> T
    ) -> Effect<T> {
        return Effect<T> { (newAction) in
            self.run { action in
                newAction(transform(action))
            }
        }
    }
 
    public func receive(
        on queue: DispatchQueue
    ) -> Effect<Action> {
        return Effect { closure in
            queue.async {
                self.run(closure)
            }
        }
    }
    
    static func zip<A, B>(
        _ a: Effect<A>,
        _ b: Effect<B>
    ) -> Effect<(A, B)> {
        return Effect<(A,B)> { (closure) in
            a.run { aAction in
                b.run{ bAction in
                    closure((aAction, bAction))
                }
            }
        }
    }
    
}

struct Parallel<A> {
  let run: (@escaping (A) -> Void) -> Void
}
public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

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
        let effects = self.reducer(&self.value, action)
        effects.forEach { $0.run(self.send) }
    }
    
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
        self.cancellableBag.insert(
            self.$value.sink { [weak localStore] (newValue) in
                localStore?.value = f(newValue)
            }
        )
        return localStore
    }
}

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    
    return { value, action in
        let effects = reducers.flatMap { $0(&value, action) }
        return effects
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

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
    
    return { globalValue, globalAction in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEffects = reducer(&globalValue[keyPath: value], localAction)
        // Local Effects를  Global Effects로 변환한다.
        return localEffects.map { localEffect in
            // GlobalEffect
            Effect<GlobalAction>(run: { (callback) in
                localEffect.run { localAction in
                    var globalAction = globalAction
                    // Global Action으로 변환한다.
                    globalAction[keyPath: action] = localAction
                    // callback을 사용하여 global effect를 가져온다.
                    callback(globalAction)
                }
            })
        }
    }
}

public func logging<Value, Action>(
    _ reducer: @escaping Reducer<Value, Action>
) -> Reducer<Value, Action> {
    
    return { value, action in
        let effects = reducer(&value, action)
        let newValue = value
        return [
            Effect(run: { _ in
                print("Action: \(action)")
                print("value:")
                dump(newValue)
                print("---")
            })
        ] + effects
    }
}

public func transform<A, B, Action>(
    _ reducer: (inout A, Action) -> Void,
    _ f: (A) -> B
) -> (inout B, Action) -> Void {
    fatalError()
}
