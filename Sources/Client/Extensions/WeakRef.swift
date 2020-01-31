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
        if isEmpty {
            return
        }
        
        // Find indices with the nil value.
        // For example values with indices: [0: nil, 1: value1, 2: nil, 3: value2]
        let nilIndices = enumerated()
            // to: [0, nil, 2, nil]
            .map({ $1.value == nil ? $0 : nil })
            // to: [0, 2]
            .compactMap({ $0 })
            // to: [2, 0]
            .reversed()
        
        // Remove each element from the end of the array.
        nilIndices.forEach({ remove(at: $0) })
    }
}
