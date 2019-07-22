//
//  IndexPath+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public extension IndexPath {
    
    /// Create an `IndexPath` with a given row and section 0.
    ///
    /// - Parameter row: a row.
    /// - Returns: an IndexPath(row: row, section: 0).
    static func row(_ row: Int) -> IndexPath {
        return IndexPath(row: row, section: 0)
    }
    
    /// Create an `IndexPath` with a given item and section 0.
    ///
    /// - Parameter item: an item.
    /// - Returns: an IndexPath(item: item, section: 0).
    static func item(_ item: Int) -> IndexPath {
        return IndexPath(item: item, section: 0)
    }
}
