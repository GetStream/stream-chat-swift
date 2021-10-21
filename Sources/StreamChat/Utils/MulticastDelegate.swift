//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// Responsible to hold a collection of delegates and call all of them when the multicast delegate is invoked.
struct MulticastDelegate<T> {
    /// We need to use a weak NSHashTable instead of a WeakReference<T> type because <T> can't
    /// be conformed to AnyObject or the rest of the codebase won't compile because of `DelegateCallable`.
    private var _additionalDelegates = NSHashTable<AnyObject>.weakObjects()

    /// Because we use `delegate` pattern from UIKit, and NSHashTable is not ordered,
    /// we need to keep a separate HashTable to distinguish a single UIKit delegate vs Combine delegates.
    private var _mainDelegate = NSHashTable<AnyObject>.weakObjects()

    /// The main delegate. If a `controller.delegate` is set, the main delegate will be used.
    var mainDelegate: T? {
        _mainDelegate.allObjects.map { $0 as! T }.first
    }

    /// The additional delegates. If a Combine publisher is being used,
    /// all subscribers will be added to the additional delegates.
    var additionalDelegates: [T] {
        _additionalDelegates.allObjects.map { $0 as! T }
    }

    /// Invokes all delegates, including the main and additional delegates.
    /// - Parameter action: The action to be performed for all delegates.
    func invoke(_ action: (T) -> Void) {
        mainDelegate.map { action($0) }
        additionalDelegates.forEach { action($0) }
    }

    /// Sets the main delegate. If is nil, removes the main delegate.
    /// - Parameter mainDelegate: The main delegate.
    mutating func set(mainDelegate: T?) {
        _mainDelegate.removeAllObjects()

        if let delegate = mainDelegate {
            _mainDelegate.add(delegate as AnyObject)
        }
    }

    /// Adds a new delegate to the additional delegates.
    /// - Parameter additionalDelegate: The additional delegate.
    mutating func add(additionalDelegate: T) {
        _additionalDelegates.add(additionalDelegate as AnyObject)
    }

    /// Removes a delegate from the additional delegates.
    /// - Parameter additionalDelegate: The delegate to be removed.
    mutating func remove(additionalDelegate: T) {
        _additionalDelegates.remove(additionalDelegate as AnyObject)
    }

    /// Replaces the current additional delegates with another collection of delegates.
    /// - Parameter additionalDelegates: The new additional delegates.
    mutating func replace(additionalDelegates: [T]) {
        _additionalDelegates.removeAllObjects()
        additionalDelegates.forEach { _additionalDelegates.add($0 as AnyObject) }
    }

    /// Removes all delegates, including the main and additional delegates.
    mutating func removeAll() {
        _additionalDelegates.removeAllObjects()
        _mainDelegate.removeAllObjects()
    }
}
