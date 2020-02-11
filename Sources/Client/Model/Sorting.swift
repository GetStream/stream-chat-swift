//
//  Sorting.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 25/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sorting options.
///
/// For example:
/// ```
/// // Sort channels by the last message date:
/// let sorting = Sorting("lastMessageDate")
/// ```
public struct Sorting: Encodable, CustomStringConvertible {
    /// A sorting field name.
    public let field: String
    /// A sorting direction.
    public let direction: Int
    
    public var description: String { "\(field):\(direction)" }
    
    /// Init sorting options.
    ///
    /// - Parameters:
    ///     - key: a key from coding keys.
    ///     - isAscending: a diration of the sorting.
    public init(_ key: String, isAscending: Bool = false) {
        field = key
        direction = isAscending ? 1 : -1
    }
}
