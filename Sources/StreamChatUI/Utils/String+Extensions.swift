//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstLowercased: String { prefix(1).lowercased() + dropFirst() }
    public var data: Data { Data(utf8) }
    public var base64Encoded: Data { data.base64EncodedData() }
    public var base64Decoded: Data? { Data(base64Encoded: string) }
}

extension LosslessStringConvertible {
    public var string: String { .init(self) }
}

extension Sequence where Element == UInt8 {
    public var data: Data { .init(self) }
    public var base64Decoded: Data? { Data(base64Encoded: data) }
    public var string: String? { String(bytes: self, encoding: .utf8) }
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
    public var isSingleEmoji: Bool { count == 1 && containsEmoji }
    
    /// Checks whether the string contains an emoji
    public var containsEmoji: Bool { contains { $0.isEmoji } }
    
    /// Checks whether the string only contains emoji
    public var containsOnlyEmoji: Bool { !isEmpty && !contains { !$0.isEmoji } }
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

    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func trimStringByFirstLastCount(firstCount: Int, lastCount: Int) -> String {
        let newString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if self.count > firstCount * 2 {
            let prefix = String(newString.prefix(firstCount))
            let suffix = String(newString.suffix(lastCount))
            return "\(prefix)...\(suffix)"
        }
        return self
    }
}

extension String {
    subscript(index: Int) -> Character {
        self[self.index(startIndex, offsetBy: index)]
    }
}

extension String {
   
    var isAlphabet: Bool {
        return !isEmpty && range(of: "[^a-zA-Z]", options: .regularExpression) == nil
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        let modifiedFont = String(format:"<span style=\"font-family: '-apple-system', 'SF PRO'; font-size: \(14)\">%@</span>", self)

        let attrStr = try! NSAttributedString(
            data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
            documentAttributes: nil)
        return attrStr
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension NSAttributedString {
    func height(containerWidth: CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: containerWidth, height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.height)
    }

    func width(containerHeight: CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: containerHeight),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.width)
    }
}
