//
//  String+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - Check the string is blank

extension String {
    /// Check if the string is empty and does not have whitespaces or newlines.
    public var isBlank: Bool {
        return isEmpty || allSatisfy({ $0.isWhitespace })
    }
}

extension Optional where Wrapped == String {
    var isBlank: Bool {
        return self?.isBlank ?? true
    }
}
