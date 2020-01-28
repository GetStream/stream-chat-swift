//
//  Atomic.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 25/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A mutable thread safe variable.
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
        queue.async(flags: .barrier) {
            let oldValue = self.value
            self.value = newValue
            self.valueChanged(from: oldValue, to: newValue)
        }
    }
    
    /// Get the value.
    public func get() -> T? {
        var currentValue: T?
        queue.sync { currentValue = self.value }
        return currentValue
    }
    
    /// Get the value if exists or return a default value.
    ///
    /// - Parameter defaultValue: a default value.
    /// - Returns: a stored value or default.
    public func get(defaultValue: T) -> T {
        return get() ?? defaultValue
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
            self.valueChanged(from: oldValue, to: newValue)
        }
    }
    
    private func valueChanged(from oldValue: T?, to newValue: T?) {
        if let callbackQueue = callbackQueue {
            callbackQueue.async { [weak self] in
                self?.didSet?(newValue, oldValue)
            }
        } else {
            didSet?(newValue, oldValue)
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
