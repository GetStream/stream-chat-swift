//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class ThreadSafeWeakCollection<T: AnyObject> {
    private let queue = DispatchQueue(label: "io.stream.com.weak-collection")
    private let storage = NSHashTable<T>.weakObjects()

    var allObjects: [T] {
        var objects: [T]!
        queue.sync {
            objects = storage.allObjects
        }
        return objects
    }

    var count: Int {
        var count: Int = 0
        queue.sync {
            count = storage.count
        }
        return count
    }

    func add(_ object: T?) {
        queue.async(flags: .barrier) {
            self.storage.add(object)
        }
    }

    func removeAllObjects() {
        queue.async(flags: .barrier) {
            self.storage.removeAllObjects()
        }
    }

    func contains(_ anObject: T?) -> Bool {
        var containsObject: Bool = false
        queue.sync {
            containsObject = storage.contains(anObject)
        }
        return containsObject
    }
}
