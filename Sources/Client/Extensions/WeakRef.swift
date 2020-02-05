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

extension Array {
    /// Remove all nil values.
    mutating func flush<T: AnyObject>() where Element == WeakRef<T> {
        self = filter { $0.value != nil }
    }
}
