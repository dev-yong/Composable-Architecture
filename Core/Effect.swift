//
//  Effect.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Foundation

private var cancellableBag = [String: Bool]()

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
    
    public func run(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            queue.async {
                self.run { a in callback(a) }
            }
        }
    }
    
    public func receive(on queue: DispatchQueue) -> Effect {
        return Effect { callback in
            self.run { a in queue.async { callback(a) } }
        }
    }
    
    public func cancellable(id: String) -> Effect {
        return Effect { callback in
            cancellableBag[id] = false
            self.run {
                guard !(cancellableBag[id] ?? false) else { return }
                callback($0)
            }
        }
    }
    
    public static func cancel(id: String) -> Effect {
      return Effect { _ in
          cancellableBag[id] = true
      }
    }
    
}
