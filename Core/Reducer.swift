//
//  Reducer.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Combine

public typealias Reducer<Value, Action, Environment> = (inout Value, Action, Environment) -> [Effect<Action>]

public func combine<Value, Action, Environment>(
    _ reducers: Reducer<Value, Action, Environment>...
) -> Reducer<Value, Action, Environment> {
    
    return { value, action, environment in
        let effects = reducers.flatMap { $0(&value, action, environment) }
        return effects
    }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction, LocalEnvironment, GlobalEnvironment>(
    _ reducer: @escaping Reducer<LocalValue, LocalAction, LocalEnvironment>,
    value: WritableKeyPath<GlobalValue, LocalValue>,
    action: WritableKeyPath<GlobalAction, LocalAction?>,
    environemnt: @escaping (GlobalEnvironment) -> LocalEnvironment
) -> Reducer<GlobalValue, GlobalAction, GlobalEnvironment> {
    
    return { globalValue, globalAction, globalEnvironment in
        guard let localAction = globalAction[keyPath: action] else { return [] }
        let localEnvironment = environemnt(globalEnvironment)
        let localEffects = reducer(&globalValue[keyPath: value], localAction, localEnvironment)
        return localEffects.map { localEffect in
            localEffect.map { localAction -> GlobalAction in
                var globalAction = globalAction
                globalAction[keyPath: action] = localAction
                return globalAction
            }
            .eraseToEffect()
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
            .fireAndForget {
                print("Action: \(action)")
                print("value:")
                dump(newValue)
                print("---")
            }
        ] + effects
    }
}

