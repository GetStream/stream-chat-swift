//
//  AssociatedValue.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 14/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Vars for Extensions

public func associated<T>(to base: AnyObject,
                          key: UnsafePointer<UInt8>,
                          policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN,
                          initialiser: () -> T) -> T {
    if let value = objc_getAssociatedObject(base, key) as? T {
        return value
    }
    
    if let value = objc_getAssociatedObject(base, key) as? Lifted<T> {
        return value.value
    }
    
    let lifted = Lifted(initialiser())
    objc_setAssociatedObject(base, key, lifted, policy)
    
    return lifted.value
}

public func associate<T>(to base: AnyObject,
                         key: UnsafePointer<UInt8>,
                         value: T,
                         policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN) {
    if let unwrappedValue: AnyObject = value as AnyObject? {
        objc_setAssociatedObject(base, key, unwrappedValue, policy)
    } else {
        objc_setAssociatedObject(base, key, lift(value), policy)
    }
}

private final class Lifted<T> {
    let value: T
    
    init(_ x: T) {
        value = x
    }
}

private func lift<T>(_ x: T) -> Lifted<T> {
    Lifted(x)
}
