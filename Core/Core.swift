//
//  Core.swift
//  Core
//
//  Created by 이광용 on 2020/11/02.
//

import Combine
import SwiftUI

public final class Store<Value, Action>: ObservableObject {
    
    public let reducer: (inout Value, Action) -> Void
    @Published
    public private(set) var value: Value
    
    public init(
        initialValue: Value,
        reducer: @escaping (inout Value, Action) -> Void
    ) {
        self.value = initialValue
        self.reducer = reducer
    }
    
    public func send(_ action: Action) {
        self.reducer(&self.value, action)
    }
}

public func combine<Value, Action>(
  _ first: @escaping (inout Value, Action) -> Void,
  _ second: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {

  return { value, action in
    first(&value, action)
    second(&value, action)
  }
}

public func combine<Value, Action>(
  _ reducers: (inout Value, Action) -> Void...
) -> (inout Value, Action) -> Void {

  return { value, action in
    for reducer in reducers {
      reducer(&value, action)
    }
  }
}

public func pullback<LocalValue, GlobalValue, Action>(
    _ reducer: @escaping (inout LocalValue, Action) -> Void,
    value: WritableKeyPath<GlobalValue, LocalValue>
) -> (inout GlobalValue, Action) -> Void {
    return { globalValue, action in
        reducer(&globalValue[keyPath: value], action)
    }
}

public func logging<Value, Action>(
    _ reducer: @escaping (inout Value, Action) -> Void
) -> (inout Value, Action) -> Void {
    
    return { value, action in
        reducer(&value, action)
        print("Action: \(action)")
        print("value:")
        dump(value)
        print("---")
    }
}
