//
//  RxFunctions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

public extension ObservableType {
    
    /// Unwrap an optional event value.
    func unwrap<T>() -> Observable<T> where Element == T? {
        return filter { $0 != nil }.map { $0! }
    }
    
    /// Map an event value to `Void()`.
    func void() -> Observable<Void> {
        return map { _ in Void() }
    }
}
