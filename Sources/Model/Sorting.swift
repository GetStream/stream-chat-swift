//
//  Sorting.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 25/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Sorting<T: CodingKey>: Encodable {
    let field: String
    let direction: Int
    
    init(_ key: T, isAscending: Bool = false) {
        field = key.stringValue
        direction = isAscending ? 1 : -1
    }
}
