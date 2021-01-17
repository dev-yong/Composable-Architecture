//
//  Publisheres+Effect.swift
//  Core
//
//  Created by 이광용 on 2021/01/11.
//

import Combine

extension Publisher where Failure == Never {
    
    public func eraseToEffect() -> Effect<Output> {
        Effect(publisher: self.eraseToAnyPublisher())
    }
    
}
