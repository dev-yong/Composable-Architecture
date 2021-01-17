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
    
}
