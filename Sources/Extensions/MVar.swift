//
//  MVar.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 25/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

final class MVar<T> {
    private let queue = DispatchQueue(label: "io.getstream.Chat.MVar", qos: .utility, attributes: .concurrent)
    private var value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    func set(_ newValue: T) {
        queue.async(flags: .barrier) { self.value = newValue }
    }
    
    func get() -> T? {
        var currentValue: T?
        queue.sync { currentValue = self.value }
        return currentValue
    }
    
    func get(defaultValue: T) -> T {
        return get() ?? defaultValue
    }
}

// MARK: - Helper Operator

extension MVar where T == Int {
    
    static func +=(lhs: MVar<T>, rhs: T) {
        if let currentValue = lhs.get() {
            lhs.set(currentValue + rhs)
        }
    }
    
    static func -=(lhs: MVar<T>, rhs: T) {
        if let currentValue = lhs.get() {
            lhs.set(currentValue - rhs)
        }
    }
}
