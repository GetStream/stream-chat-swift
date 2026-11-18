//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The specification's static checks on a `regex` pattern, which the agent writes: its length,
// constructs its dialect leaves out, and a quantifier that repeats a group holding an unbounded
// one, such as `(a+)+`, which backtracks catastrophically. Matching still has a timeout for the
// patterns these checks don't catch.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIRegexSafety {
    static let maxPatternLength = 256
    static let maxValueLength = 4096

    // What makes the pattern unsafe or outside the dialect, or nil when it passes the checks.
    static func problem(in pattern: String) -> String? {
        let scalars = Array(pattern.unicodeScalars)
        guard scalars.count <= maxPatternLength else {
            return "it is longer than \(maxPatternLength) characters."
        }
        // Whether each open group, the whole pattern first, holds an unbounded quantifier.
        var groups = [false]
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            switch scalar {
            case "\\":
                guard index + 1 < scalars.count else { return "it ends with a lone backslash." }
                let escaped = scalars[index + 1]
                if ("1"..."9").contains(escaped) || ["k", "p", "P", "c"].contains(escaped) {
                    return "'\\\(escaped)' isn't allowed."
                }
                index += 2
                if escaped == "u", index < scalars.count, scalars[index] == "{" {
                    while index < scalars.count, scalars[index] != "}" { index += 1 }
                    index += 1
                }
            case "[":
                index += 1
                while index < scalars.count, scalars[index] != "]" {
                    index += scalars[index] == "\\" ? 2 : 1
                }
                index += 1
            case "(":
                if index + 1 < scalars.count, scalars[index + 1] == "?" {
                    guard index + 2 < scalars.count, [":", "=", "!"].contains(scalars[index + 2]) else {
                        return "lookbehind, named groups and inline flags aren't allowed."
                    }
                    index += 3
                } else {
                    index += 1
                }
                groups.append(false)
                continue
            case ")":
                guard groups.count > 1 else { return "it closes a group it doesn't open." }
                let holdsUnbounded = groups.removeLast()
                index += 1
                let quantifier = self.quantifier(at: &index, in: scalars)
                if holdsUnbounded, let quantifier, quantifier.upper > 1 {
                    return "it repeats a group that repeats without bound, which can take minutes to match."
                }
                groups[groups.count - 1] = groups[groups.count - 1] || holdsUnbounded || quantifier?.isUnbounded == true
                continue
            case "|", "^", "$":
                index += 1
                continue
            default:
                index += 1
            }
            if quantifier(at: &index, in: scalars)?.isUnbounded == true {
                groups[groups.count - 1] = true
            }
        }
        return groups.count == 1 ? nil : "it opens a group it doesn't close."
    }

    private struct Quantifier {
        let upper: Int
        var isUnbounded: Bool { upper == .max }
    }

    // The quantifier at `index`, if there is one, moving past it and its lazy `?`.
    private static func quantifier(at index: inout Int, in scalars: [Unicode.Scalar]) -> Quantifier? {
        guard index < scalars.count else { return nil }
        let quantifier: Quantifier
        switch scalars[index] {
        case "*", "+":
            quantifier = Quantifier(upper: .max)
            index += 1
        case "?":
            quantifier = Quantifier(upper: 1)
            index += 1
        case "{":
            var end = index + 1
            var digits = ""
            var sawComma = false
            var upperDigits = ""
            while end < scalars.count, scalars[end] != "}" {
                let scalar = scalars[end]
                if scalar == "," && !sawComma {
                    sawComma = true
                } else if ("0"..."9").contains(scalar) {
                    if sawComma { upperDigits.unicodeScalars.append(scalar) } else { digits.unicodeScalars.append(scalar) }
                } else {
                    return nil
                }
                end += 1
            }
            guard end < scalars.count, !digits.isEmpty else { return nil }
            let lower = Int(digits) ?? .max
            if !sawComma {
                quantifier = Quantifier(upper: lower)
            } else if upperDigits.isEmpty {
                quantifier = Quantifier(upper: .max)
            } else {
                quantifier = Quantifier(upper: Int(upperDigits) ?? .max)
            }
            index = end + 1
        default:
            return nil
        }
        if index < scalars.count, scalars[index] == "?" {
            index += 1
        }
        return quantifier
    }
}
