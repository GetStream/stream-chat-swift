//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A wrapper object that allows attaching additional delegates and call the callbacks on all of them.
///
/// - Warning: ⚠️ Because `MulticastDelegate` keeps strong references to the delegates, it's strongly recommended to use
/// an additional wrapper which will make sure the delegate instance is referenced only weakly.
struct MulticastDelegate<WrappedDelegate> {
    /// Invokes the delegate callback on all delegates.
    func invoke(_ action: (WrappedDelegate) -> Void) {
        if let main = mainDelegate {
            action(main)
        }
        additionalDelegates.forEach { action($0) }
    }
    
    /// The is usually the delegate instance you want to expose to your users as _the_ delegate.
    var mainDelegate: WrappedDelegate?
    
    /// Aditional delegates that receive the same callback as the main one. These delegates receive callbacks also when
    /// the main delegate is not set.
    var additionalDelegates: [WrappedDelegate] = []
}
