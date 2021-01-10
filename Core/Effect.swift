//
//  Effect.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Combine

public struct Effect<Output>: Publisher {
    
    public typealias Failure = Never
    
    let publisher: AnyPublisher<Output, Failure>

    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Failure == S.Failure, Output == S.Input {
      self.publisher.receive(
        subscriber: subscriber
      )
    }
    
}
