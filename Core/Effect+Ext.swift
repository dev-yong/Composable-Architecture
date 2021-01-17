//
//  Effect+Ext.swift
//  Core
//
//  Created by 이광용 on 2021/01/18.
//

import Combine

extension Effect {
    
    public static func fireAndForget(
        work: @escaping () -> Void
    ) -> Effect {
        return Deferred { () -> Empty<Output, Never> in
            work()
            return Empty(completeImmediately: true)
        }.eraseToEffect()
    }
    
    public static func sync(
        work: @escaping () -> Output
    ) ->  Effect {
        return Deferred { () -> Just<Output> in
            Just(work())
        }.eraseToEffect()
    }
    
    public static func async(
        work: @escaping (@escaping (Output) -> Void) -> Void
    ) -> Effect {
        return Deferred {
            Future<Output, Never> { promise in
                work { output in
                    promise(.success(output))
                }
            }
        }.eraseToEffect()
    }
    
}
