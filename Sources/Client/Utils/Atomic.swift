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
    
    private let queue = DispatchQueue(label: "io.getstream.Chat.Atomic", qos: .userInitiated, attributes: .concurrent)
    private var value: T?
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
        queue.async(flags: .barrier) { [weak self] in
            let oldValue = self?.value
            self?.value = newValue
            self?.valueChanged(newValue, oldValue)
        }
    }
    
    /// Get the value.
    public func get() -> T? {
        var currentValue: T?
        queue.sync { [weak self] in currentValue = self?.value }
        return currentValue
    }
    
    /// Get the value if exists or return a default value.
    ///
    /// - Parameter default: a default value.
    /// - Returns: a stored value or default.
    public func get(default: T) -> T {
        return get() ?? `default`
    }
    
    /// Update the value safely.
    /// - Parameter changes: a block with changes. It should return a new value.
    public func update(_ changes: @escaping (T) -> T) {
        queue.async(flags: .barrier) {
            guard let oldValue = self.value else {
                return
            }
            
            let newValue = changes(oldValue)
            self.value = newValue
            self.valueChanged(newValue, oldValue)
        }
    }
    
    private func valueChanged(_ newValue: T?, _ oldValue: T?) {
        if let callbackQueue = callbackQueue {
            callbackQueue.async { [weak self] in self?.didSet?(newValue, oldValue) }
        } else {
            didSet?(newValue, oldValue)
        }
    }
}

// MARK: - Helper Updates

public extension Atomic {
    
    func update<Value>(_ keyPath: WritableKeyPath<T, Value>, to value: Value) {
        update { instance in
            var instance = instance
            instance[keyPath: keyPath] = value
            return instance
        }
    }
    
    func append<Value>(to keyPath: WritableKeyPath<T, [Value]>, _ value: Value) {
        update { instance in
            var instance = instance
            instance[keyPath: keyPath].append(value)
            return instance
        }
    }
    
    subscript<Value>(dynamicMember keyPath: WritableKeyPath<T, Value>) -> Value? {
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

// MARK: - Helper Operator

public extension Atomic where T == Int {
    
    static func += (lhs: Atomic<T>, rhs: T) {
        if let currentValue = lhs.get() {
            lhs.set(currentValue + rhs)
        }
    }
    
    static func -= (lhs: Atomic<T>, rhs: T) {
        if let currentValue = lhs.get() {
            lhs.set(currentValue - rhs)
        }
    }
}
