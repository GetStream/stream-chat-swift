//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol to which all controllers conform to.
///
/// This protocol is not meant to be adopted by your custom types.
///
public protocol Controller {
    /// The queue which is used to perform callback calls
    var callbackQueue: DispatchQueue { get set }
}

extension Controller {
    /// A helper function to ensure the callback is performed on the callback queue.
    func callback(_ action: @escaping () -> Void) {
        if callbackQueue == .main, Thread.current.isMainThread {
            // Perform the action on the main queue synchronously
            action()
        } else {
            callbackQueue.async {
                action()
            }
        }
    }
}
