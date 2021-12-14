//
//  Array+SafeSubscript.swift
//  StreamChat
//
//  Created by Pol Quintana on 14/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
