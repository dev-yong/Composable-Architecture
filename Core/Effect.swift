//
//  Effect.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Foundation

public struct Effect<A> {
    
    public let run: (@escaping (A) -> Void) -> Void
    
    public init(run: @escaping (@escaping (A) -> Void) -> Void) {
        self.run = run
    }
    
    public func map<B>(_ transform: @escaping (A) -> B) -> Effect<B> {
        return Effect<B> { callback in
            self.run { callback(transform($0)) }
        }
    }
    
    public func receive(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            self.run { a in queue.async { callback(a) } }
        }
    }
    
}
