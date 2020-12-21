//
//  Effect.swift
//  Core
//
//  Created by 이광용 on 2020/12/19.
//

import Foundation

private var cancellableBag = [AnyHashable: DispatchWorkItem]()
private var cancellablesLock = os_unfair_lock_s()

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
    
    public func cancellable(id: AnyHashable) -> Effect {
        return Effect { callback in
            let workItem = DispatchWorkItem {
                self.run {
                    os_unfair_lock_lock(&cancellablesLock)
                    if !(cancellableBag[id]?.isCancelled ?? true) {
                        callback($0)
                    }
                    os_unfair_lock_unlock(&cancellablesLock)
                }
            }
            os_unfair_lock_lock(&cancellablesLock)
            cancellableBag[id] = workItem
            os_unfair_lock_unlock(&cancellablesLock)
            workItem.perform()
        }
    }
    
    public static func cancel(id: AnyHashable) -> Effect {
      return Effect { _ in
        os_unfair_lock_lock(&cancellablesLock)
        defer { os_unfair_lock_unlock(&cancellablesLock) }
        cancellableBag[id]?.cancel()
      }
    }
    
}
