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
    func callback(_ action: @escaping () -> Void) {
        if Thread.current.isMainThread {
            if callbackQueue == .main {
                action()
            } else {
                callbackQueue.async(execute: action)
            }
        } else {
            callbackQueue.sync(execute: action)
        }
    }
}
