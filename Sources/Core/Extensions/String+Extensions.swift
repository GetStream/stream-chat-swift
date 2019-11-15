//
//  String+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Check the string is blank

extension String {
    /// Check if the string is empty and does not have whitespaces or newlines.
    public var isBlank: Bool {
        return isEmpty || allSatisfy({ $0.isWhitespace })
    }
}

// MARK: - Links

extension String {
    
    /// Checks if the string probably has an URL, e.g. "ab.io", "a7.io"
    /// - Note:
    ///   - length > 4
    ///   - has dot
    ///   - 2 chars after the dot are letters
    ///   - 2 chars before the dot are a letter + a letter or a digit
    ///   - 3 or 4 char is a space or a new line
    public var probablyHasURL: Bool {
        guard count > 4, let dotIndex = lastIndex(of: "."), dotIndex < endIndex, dotIndex > startIndex else {
            return false
        }
        
        if count > 11, contains("://") {
            return true
        }
        
        let afterDotIndex = index(after: dotIndex)
        
        guard afterDotIndex < endIndex else {
            return false
        }
        
        let afterAfterDotIndex = index(after: afterDotIndex)
        
        // Check "a7.i❌"
        guard afterAfterDotIndex < endIndex else {
            return false
        }
        
        let beforeDotIndex = index(before: dotIndex)
        
        guard beforeDotIndex > startIndex else {
            return false
        }
        
        let beforeBeforeDotIndex = index(before: beforeDotIndex)
        
        // Check "❌a.io"
        guard beforeBeforeDotIndex >= startIndex else {
            return false
        }
        
        // Checks "a7.io"
        return self[beforeBeforeDotIndex].isLetter
            && (self[beforeDotIndex].isLetter || self[beforeDotIndex].isNumber)
            && self[afterDotIndex].isLetter
            && self[afterAfterDotIndex].isLetter
    }
    
    private func isSpaceOrNewLine(at index: Index) -> Bool {
        return self[index].isWhitespace || self[index].isNewline
    }
    
    private func isSlash(at index: Index) -> Bool {
        return self[index] == "/"
    }
}

// MARK: - Optional String

extension Optional where Wrapped == String {
    var isBlank: Bool {
        return self?.isBlank ?? true
    }
}
