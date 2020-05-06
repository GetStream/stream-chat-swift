//
//  Atomic.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 25/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A mutable thread safe variable.
@dynamicMemberLookup
public final class Atomic<T> {
    /// A didSet callback type.
    public typealias DidSetCallback = (_ value: T?, _ oldValue: T?) -> Void

    private let lock = NSRecursiveLock()

    private var value: T? {
        didSet {
            if let callbackQueue = callbackQueue {
                callbackQueue.async {
                    self.didSet?(self.value, oldValue)
                }

            } else {
                didSet?(value, oldValue)
            }
        }
    }

    private var didSet: DidSetCallback?
    private var callbackQueue: DispatchQueue?

    /// Init a Atomic.
    ///
    /// - Parameters:
    ///   - value: an initial value.
    ///   - didSet: a didSet callback.
    public init(_ value: T? = nil, callbackQueue: DispatchQueue? = .global(qos: .userInitiated), _ didSet: DidSetCallback? = nil) {
        self.value = value
        self.callbackQueue = callbackQueue
        self.didSet = didSet
    }
    
    /// Set a value.
    public func set(_ newValue: T?) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    public func get() -> T? {
        lock.lock(); defer { lock.unlock() }
        return value

    }
    
    /// Get the value if exists or return a default value.
    ///
    /// - Parameter default: a default value.
    /// - Returns: a stored value or default.
    public func get(default: T) -> T {
        get() ?? `default`
    }
    
    /// Update the value safely.
    /// - Parameter changes: a block with changes. It should return a new value.
    public func update(_ changes: (T) -> T?) {
        lock.lock()
        if let currentValue = value {
            value = changes(currentValue)
        }
        lock.unlock()
    }
}

// MARK: - Helper Updates

public extension Atomic {
    
    /// Updates a sub value at the given keypath.
    /// - Parameters:
    ///   - keyPath: a keypath.
    ///   - value: a new value.
    func update<Element>(_ keyPath: WritableKeyPath<T, Element>, to value: Element) {
        update { instance in
            var instance = instance
            instance[keyPath: keyPath] = value
            return instance
        }
    }
    
    /// Adds an element to the end of the collection at the given keypath.
    /// - Parameters:
    ///   - keyPath: a keypath.
    ///   - value: a new value of the collection.
    func append<Element>(to keyPath: WritableKeyPath<T, [Element]>, _ value: Element) {
        update { instance in
            var instance = instance
            instance[keyPath: keyPath].append(value)
            return instance
        }
    }
    
    /// Accesses a sub value by the given keypath.
    subscript<Element>(dynamicMember keyPath: WritableKeyPath<T, Element>) -> Element? {
        get {
            return get()?[keyPath: keyPath]
        }
        set {
            if let newValue = newValue {
                update(keyPath, to: newValue)
            }
        }
    }
}

// MARK: - Helper for Collection

public extension Atomic where T: Collection {
    /// Get a value by key.
    // swiftlint:disable:next syntactic_sugar
    subscript<Key: Hashable, Value>(key: Key) -> Value? where T == Dictionary<Key, Value> {
        lock.lock(); defer { lock.unlock() }
        return value?[key]
    }
}

// MARK: - Helper Operator

public extension Atomic where T == Int {
    
    /// Adds two values and stores the result in the left-hand-side variable.
    /// - Parameters:
    ///   - lhs: the current atomic value.
    ///   - rhs: the second value.
    static func += (lhs: Atomic<T>, rhs: T) {
        lhs.update {
            $0 + rhs
        }
    }
    
    /// Subtracts the second value from the first and stores the difference in the left-hand-side variable.
    /// - Parameters:
    ///   - lhs: the current atomic value.
    ///   - rhs: the second value.
    static func -= (lhs: Atomic<T>, rhs: T) {
        lhs.update {
            $0 - rhs
        }
    }
}
