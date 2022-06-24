//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
        callbackQueue.async { action }
    }
}
