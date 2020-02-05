//
//  String+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import CommonCrypto

// MARK: Hashing

extension String {
    /// A string format to conver bytes to string.
    public static let dataToHEXFormat = "%02hhx"
    
    /// Returns a MD5 hash for the string.
    public var md5: String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, self, CC_LONG(lengthOfBytes(using: .utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        return digest.map({ String(format: String.dataToHEXFormat, $0) }).joined()
    }
}

// MARK: Helpers

extension String {
    private static let fileNameCharacterSet = CharacterSet.lowercaseLetters.union(.decimalDigits).union(.init(charactersIn: "_"))
    
    /// Get an URL from the string.
    public var url: URL? {
        return URL(string: self)
    }
    
    /// Check if the string is empty and does not have whitespaces or newlines.
    public var isBlank: Bool {
        return isEmpty || allSatisfy({ $0.isWhitespace })
    }
    
    /// Get a safe filnename from the string.
    public func fileName(limit: Int = 20) -> String {
        var fileName = String(UnicodeScalarView(lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .unicodeScalars
            .lazy
            .filter({ String.fileNameCharacterSet.contains($0) })))
        
        if fileName.count > limit {
            fileName = String(fileName.prefix(limit))
        }
        
        return fileName
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
        self[index].isWhitespace || self[index].isNewline
    }
    
    private func isSlash(at index: Index) -> Bool {
        self[index] == "/"
    }
}

// MARK: - Optional String

extension Optional where Wrapped == String {
    /// Checks if the optional String is empty or blank.
    public var isBlank: Bool {
        self?.isBlank ?? true
    }
}
