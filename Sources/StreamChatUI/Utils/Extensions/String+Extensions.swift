//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstLowercased: String { prefix(1).lowercased() + dropFirst() }
}

// MARK: - Emoji

extension Character {
    /// Returns whether the character is an emoji
    ///
    /// An emoji can either be a 2 byte unicode character or a normal UTF8 character with an emoji modifier appended as is the case with 3️⃣
    ///
    /// 0x238C is the first instance of UTF16 emoji that requires no modifier.
    /// `isEmoji` on the `UnicodeScalar` will evaluate to `true` for any character that can be turned into an emoji by adding a modifier such as the digit "3".
    /// To avoid this we confirm that any character below `0x238C` has an emoji modifier attached
    ///
    ///
    /// This code snippet is taken from [StackOverflow](https://stackoverflow.com/a/39425959/3825788) and modified to suit the needs.
    /// Also, [Understanding Swift Strings](https://betterprogramming.pub/understanding-swift-strings-characters-and-scalars-a4b82f2d8fde) has been referred
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238c || unicodeScalars.count > 1)
    }
}

extension String {
    /// Checks whether a string is a single emoji
    var isSingleEmoji: Bool { count == 1 && containsEmoji }
    
    /// Checks whether the string contains an emoji
    var containsEmoji: Bool { contains { $0.isEmoji } }
    
    /// Checks whether the string only contains emoji
    var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }
}

extension String {
    /// computes levenshtein distance with another string (0
    public func levenshtein(_ other: String) -> Int {
        let sCount = count
        let oCount = other.count

        guard sCount != 0 else {
            return oCount
        }

        guard oCount != 0 else {
            return sCount
        }

        let line: [Int] = Array(repeating: 0, count: oCount + 1)
        var mat: [[Int]] = Array(repeating: line, count: sCount + 1)

        for i in 0...sCount {
            mat[i][0] = i
        }

        for j in 0...oCount {
            mat[0][j] = j
        }

        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1] // no operation
                } else {
                    let del = mat[i - 1][j] + 1 // deletion
                    let ins = mat[i][j - 1] + 1 // insertion
                    let sub = mat[i - 1][j - 1] + 1 // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }

        return mat[sCount][oCount]
    }
}

extension String {
    subscript(index: Int) -> Character {
        self[self.index(startIndex, offsetBy: index)]
    }
}
