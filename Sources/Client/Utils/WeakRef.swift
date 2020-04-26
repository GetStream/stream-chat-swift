//
//  WeakRef.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 29/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

final class WeakRef<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

// MARK: WeakRef Atomic Array

extension Atomic where T: Collection {
    
    /// Appends a weak reference to the element.
    /// - Parameter newElement: a new weak reference element.
    func add<Key: Hashable, C: Collection, E: AnyObject>(_ element: E, key: Key)
        where T == Dictionary<Key, C>, C.Element == WeakRef<E> { // swiftlint:disable:this syntactic_sugar
            update {
                var newValue = $0
                let weakRef = WeakRef(element)
                
                if let collection = $0[key] as? [WeakRef<E>] {
                    var collection = collection
                    collection.append(weakRef)
                    
                    if let collection = collection as? C {
                        newValue[key] = collection
                    }
                } else if let collection = [weakRef] as? C {
                    newValue[key] = collection
                }
                
                return newValue
            }
    }
    
    /// Removes all nil values.
    func flush<Key: Hashable, C: Collection, E: AnyObject>()
        where T == Dictionary<Key, C>, C.Element == WeakRef<E> { // swiftlint:disable:this syntactic_sugar
            update {
                var newValue: [Key: C] = [:]
                
                $0.forEach { (key, collection) in
                    let newCollection = collection.filter { $0.value != nil }
                    
                    if !newCollection.isEmpty, let collection = newCollection as? C {
                        newValue[key] = collection
                    }
                }
                
                return newValue
            }
    }
}
