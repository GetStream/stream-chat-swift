//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct MulticastDelegate<T> {
    private var _delegates = NSHashTable<AnyObject>.weakObjects()

    var delegates: [T] {
        _delegates.allObjects.map { $0 as! T }
    }

    func invoke(_ action: (T) -> Void) {
        delegates
            .forEach { action($0) }
    }

    func add(_ delegate: T) {
        _delegates.add(delegate as AnyObject)
    }

    func remove(_ delegate: T) {
        _delegates.remove(delegate as AnyObject)
    }

    func removeAll() {
        _delegates.removeAllObjects()
    }
}
