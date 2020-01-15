//
//  Dictionary+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// Creates a dictionary by merging the given dictionary into this
/// dictionary, replacing values with values of the other dictionary.
extension Dictionary {
    func merged(with other: Dictionary) -> Dictionary {
        return merging(other) { _, new in new }
    }
}
