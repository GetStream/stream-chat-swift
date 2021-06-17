//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

final class Cache<Key: Hashable, Value> {
    private let wrapped: NSCache<WrappedKey, Entry>
    
    init(countLimit: Int = 0) {
        wrapped = .init()
        wrapped.countLimit = countLimit
    }

    subscript(key: Key) -> Value? {
        get { value(forKey: key) }
        set {
            guard let value = newValue else {
                removeValue(forKey: key)
                return
            }
            insert(value, forKey: key)
        }
    }
    
    func insert(_ value: Value, forKey key: Key) {
        wrapped.setObject(.init(value: value), forKey: .init(key))
    }

    func value(forKey key: Key) -> Value? {
        wrapped.object(forKey: .init(key))?.value
    }

    func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: .init(key))
    }
    
    func removeAllObjects() {
        wrapped.removeAllObjects()
    }
}

private extension Cache {
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
    
    final class Entry {
        let value: Value

        init(value: Value) {
            self.value = value
        }
    }
}
