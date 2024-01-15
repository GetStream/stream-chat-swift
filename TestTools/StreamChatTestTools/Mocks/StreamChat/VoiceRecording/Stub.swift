//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol Stub: AnyObject {
    var stubbedProperties: [String: Any] { get set }

    func stubProperty<T>(_ keyPath: KeyPath<Self, T>, with value: T)
    func removePropertyStub<T>(_ keyPath: KeyPath<Self, T>)
}

extension Stub {
    public func stubProperty<T>(
        _ keyPath: KeyPath<Self, T>,
        with value: T
    ) {
        let keyPathName = NSExpression(forKeyPath: keyPath).keyPath
        stubbedProperties[keyPathName] = value
    }

    public func removePropertyStub<T>(
        _ keyPath: KeyPath<Self, T>
    ) {
        let keyPathName = NSExpression(forKeyPath: keyPath).keyPath
        stubbedProperties[keyPathName] = nil
    }

    public subscript<T>(
        dynamicMember keyPath: KeyPath<Self, T>
    ) -> T {
        let keyPathName = NSExpression(forKeyPath: keyPath).keyPath
        return (stubbedProperties[keyPathName] as? T) ?? self[keyPath: keyPath]
    }
}
