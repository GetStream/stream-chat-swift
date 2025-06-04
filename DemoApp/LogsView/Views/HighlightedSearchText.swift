//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 15, *)
struct HighlightedSearchText: View {
    let text: String
    let searchText: String
    /// Number of characters to show before and after the search text
    var searchResultLength: Int = 100

    var body: some View {
        if searchText.isEmpty {
            Text(text)
        } else {
            let (attributedString, _) = highlightedAttributedStringWithContext()
            Text(AttributedString(attributedString))
        }
    }

    /// Returns the attributed string and the range of the highlight in the trimmed string
    private func highlightedAttributedStringWithContext() -> (NSAttributedString, NSRange?) {
        guard !searchText.isEmpty,
              let range = text.range(of: searchText, options: .caseInsensitive) else {
            return (NSAttributedString(string: text), nil)
        }

        let matchLower = text.distance(from: text.startIndex, to: range.lowerBound)
        let matchUpper = text.distance(from: text.startIndex, to: range.upperBound)
        let matchLength = matchUpper - matchLower
        let maxLen = text.count

        let contextLength = searchResultLength
        var start = max(0, matchLower)
        var end = min(text.count, matchUpper + contextLength)

        let additionalLength = matchUpper + contextLength - end
        if additionalLength > 0 {
            start = max(0, start - additionalLength)
        }

        let startIdx = text.index(text.startIndex, offsetBy: start)
        let endIdx = text.index(text.startIndex, offsetBy: end)
        var trimmed = String(text[startIdx..<endIdx])

        // Add ellipsis if trimmed
        let prefixEllipsis = start > 0
        let suffixEllipsis = end < text.count
        if prefixEllipsis { trimmed = "…" + trimmed }
        if suffixEllipsis { trimmed += "…" }

        // Calculate the range of the search text in the trimmed string
        let highlightStart = (prefixEllipsis ? 1 : 0) + matchLower - start
        let highlightLength = matchLength
        let highlightRange = NSRange(location: highlightStart, length: highlightLength)

        let attributedString = NSMutableAttributedString(string: trimmed)
        let highlightColor = UIColor.systemYellow.withAlphaComponent(0.3)
        if highlightRange.location >= 0 && NSMaxRange(highlightRange) <= attributedString.length {
            attributedString.addAttribute(.backgroundColor, value: highlightColor, range: highlightRange)
        }
        return (attributedString, highlightRange)
    }
}
