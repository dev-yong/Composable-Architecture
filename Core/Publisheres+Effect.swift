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


extension Publisher {
    
    public func hush() -> Effect<Output> {
        self.map(Optional.some)
            .replaceError(with: nil)
            .compactMap { $0 }
            .eraseToEffect()
    }
    
}
