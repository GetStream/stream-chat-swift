//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A wrapper that keeps a weak ref to the underlaying object.
struct Weak<T> {
    private weak var storage: AnyObject?
    
    /// The reference to wrapped object. Equals `nil` if it's already deallocated.
    var value: T? {
        get { storage.map { $0 as! T } }
        set { storage = newValue.map { $0 as AnyObject } }
    }
    
    /// Creates a new wrapper around the given object.
    /// - Parameter value: The object to wrap.
    init(value: T) {
        self.value = value
    }
}
