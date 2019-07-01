//
//  Utils.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 27/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import ObjectiveC

/// https://twitter.com/UINT_MIN/status/836316697388695552
@available(*, deprecated, message: "Implement this!")
var TODO: Never {
    fatalError("💥 Unimplemented!")
}

/// https://twitter.com/shaps/status/836353195098189824
@available(*, deprecated, message: "🛠 Fix this code!")
var FIXME: Void { return }

// MARK: - Vars for extensions

func associated<T>(to base: AnyObject,
                   key: UnsafePointer<UInt8>,
                   policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC,
                   _ initializer: () -> T) -> T {
    if let value = objc_getAssociatedObject(base, key) as? T {
        return value
    }
    
    if let value = objc_getAssociatedObject(base, key) as? Lifted<T> {
        return value.value
    }
    
    let lifted = Lifted(initializer())
    objc_setAssociatedObject(base, key, lifted, policy)
    
    return lifted.value
}

func associate<T>(to base: AnyObject,
                  key: UnsafePointer<UInt8>,
                  value: T,
                  policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
    if let unwrappedValue: AnyObject = value as AnyObject? {
        objc_setAssociatedObject(base, key, unwrappedValue, policy)
    } else {
        objc_setAssociatedObject(base, key, Lifted(value), policy)
    }
}

private final class Lifted<T> {
    let value: T
    
    init(_ x: T) {
        value = x
    }
}
