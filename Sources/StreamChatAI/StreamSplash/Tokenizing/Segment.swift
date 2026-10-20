/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// A representation of a segment of code, used to determine the type
/// of a given token when passed to a `SyntaxRule` implementation.
struct Segment {
    /// The code that prefixes this segment, that is all the characters
    /// up to where the segment's current token begins.
    var prefix: Substring
    /// The collection of tokens that the segment includes
    var tokens: Tokens
    /// Any whitespace that immediately follows the segment's current token
    var trailingWhitespace: String?

    internal let currentTokenIsDelimiter: Bool
    internal var isLastOnLine: Bool
}

extension Segment {
    /// A collection of tokens included in a code segment
    struct Tokens {
        /// All tokens that have been found so far (excluding the current one)
        var all: [String]
        /// The number of times a given token has been found up until this point
        var counts: [String: Int]
        /// The tokens that were previously found on the same line as the current one
        var onSameLine: [String]
        /// The token that was previously found (may be on a different line)
        var previous: String?
        /// The current token which is currently being evaluated
        var current: String
        /// Any upcoming token that will follow the current one
        var next: String?
    }
}

extension Segment.Tokens {
    /// Return the number of times a given token has been found up until this point.
    /// This is a convenience API over the `counts` dictionary.
    func count(of token: String) -> Int {
        return counts[token] ?? 0
    }
}
