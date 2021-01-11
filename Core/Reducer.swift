//
//  Reducer.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Foundation

public typealias Reducer<Value, Action> = (inout Value, Action) -> [Effect<Action>]

public func combine<Value, Action>(
    _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
    
    return { value, action in
        let effects = reducers.flatMap { $0(&value, action) }
        return effects
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
            Effect { callback in
                // Local Effect로 부터 나온 LocalAction을
                localEffect.sink { localAction in
                    var globalAction = globalAction
                    // Global Action으로 변환한다.
                    globalAction[keyPath: action] = localAction
                    // callback을 사용하여 global effect를 가져온다.
                    callback(globalAction)
                }
            }
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
            Effect { _ in
                print("Action: \(action)")
                print("value:")
                dump(newValue)
                print("---")
            }
        ] + effects
    }
}
