//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// The A2UI regex dialect, a portable subset of ECMAScript patterns, which the agent writes. A
// pattern is parsed, checked against the specification's four safety rules, and written again in
// ICU's syntax, so that NSRegularExpression matches it as ECMAScript's Unicode mode would. Matching
// still has a timeout for the slow patterns the rules don't catch.
//
// - Dialect, safety check and examples: https://github.com/a2ui-project/a2ui/blob/main/specification/v1_0/docs/a2ui_protocol.md#the-regex-function
// - Basic catalog guide: https://github.com/a2ui-project/a2ui/blob/main/catalogs/basic/v1/basic_catalog_implementation_guide.md#regex
// - Conformance cases: https://github.com/a2ui-project/a2ui/blob/main/conformance/core/functions.yaml
// - The pattern's description for the agent: https://github.com/a2ui-project/a2ui/blob/main/catalogs/basic/v1/catalog.json
@available(iOS 15.0, macOS 12.0, *)
enum A2UIRegex {
    static let maxPatternLength = 256
    static let maxValueLength = 4096
    // The specification sets no limit on a count such as `{2,5}`; the reference renderers stop here.
    static let maxCount = 65535

    // Why a pattern can't be used, with the code the conformance suite expects in the error.
    struct Rejection: Error, Equatable {
        enum Code: String {
            case patternTooLong = "PATTERN_TOO_LONG"
            case unsupportedSyntax = "UNSUPPORTED_SYNTAX"
            case nestedQuantifier = "NESTED_QUANTIFIER"
            case overlappingAlternation = "OVERLAPPING_ALTERNATION"
            case adjacentOverlap = "ADJACENT_OVERLAP"
        }

        let code: Code
        let reason: String
    }

    static func expression(for pattern: String) throws -> NSRegularExpression {
        let translated = try icuPattern(for: pattern)
        do {
            return try NSRegularExpression(pattern: translated)
        } catch {
            throw Rejection(code: .unsupportedSyntax, reason: "it isn't a valid regular expression.")
        }
    }

    // The pattern in ICU's syntax, throwing a `Rejection` for one outside the dialect or its safety rules.
    static func icuPattern(for pattern: String) throws -> String {
        let scalars = Array(pattern.unicodeScalars.prefix(maxPatternLength + 1))
        guard scalars.count <= maxPatternLength else {
            throw Rejection(code: .patternTooLong, reason: "it is longer than \(maxPatternLength) code points.")
        }
        var parser = Parser(scalars: scalars)
        let node = try parser.parse()
        if let rejection = node.safetyRejection {
            throw rejection
        }
        // NSRegularExpression rejects an empty pattern, which matches anywhere.
        let translated = node.icuPattern
        return translated.isEmpty ? "(?:)" : translated
    }
}

// MARK: - Syntax tree

@available(iOS 15.0, macOS 12.0, *)
private extension A2UIRegex {
    enum Assertion {
        case start
        case end
        case wordBoundary
        case notWordBoundary
    }

    struct Repetition {
        let min: Int
        let max: Int?
        let isLazy: Bool
    }

    indirect enum Node {
        case empty
        case scalars(ScalarSet)
        case assertion(Assertion)
        case lookahead(Node, isNegative: Bool)
        case group(Node, isCapturing: Bool)
        case sequence([Node])
        case alternation([Node])
        case repetition(Node, Repetition)
    }

    // Code points as sorted ranges that neither overlap nor touch, leaving out the surrogates, which
    // a Swift string can't hold.
    struct ScalarSet {
        static let empty = ScalarSet([])
        static let digits = ScalarSet([0x30...0x39])
        static let wordCharacters = ScalarSet([0x30...0x39, 0x41...0x5a, 0x5f...0x5f, 0x61...0x7a])
        // ECMAScript's WhiteSpace and LineTerminator.
        static let whitespace = ScalarSet([
            0x09...0x0d, 0x20...0x20, 0xa0...0xa0, 0x1680...0x1680, 0x2000...0x200a,
            0x2028...0x2029, 0x202f...0x202f, 0x205f...0x205f, 0x3000...0x3000, 0xfeff...0xfeff
        ])
        // Everything but ECMAScript's line terminators.
        static let dot = ScalarSet([0x0a...0x0a, 0x0d...0x0d, 0x2028...0x2029]).inverted

        let ranges: [ClosedRange<UInt32>]

        init(_ ranges: [ClosedRange<UInt32>]) {
            var merged: [ClosedRange<UInt32>] = []
            for range in ranges.flatMap(Self.withoutSurrogates).sorted(by: { $0.lowerBound < $1.lowerBound }) {
                if let last = merged.last, range.lowerBound <= last.upperBound + 1 {
                    merged[merged.count - 1] = last.lowerBound...Swift.max(last.upperBound, range.upperBound)
                } else {
                    merged.append(range)
                }
            }
            self.ranges = merged
        }

        init(_ scalar: Unicode.Scalar) {
            self.init([scalar.value...scalar.value])
        }

        // The sets for `\d`, `\D`, `\w`, `\W`, `\s` and `\S`.
        static func classEscape(_ scalar: Unicode.Scalar) -> ScalarSet? {
            switch scalar {
            case "d": return digits
            case "D": return digits.inverted
            case "w": return wordCharacters
            case "W": return wordCharacters.inverted
            case "s": return whitespace
            case "S": return whitespace.inverted
            default: return nil
            }
        }

        var inverted: ScalarSet {
            var gaps: [ClosedRange<UInt32>] = []
            var next: UInt32 = 0
            for range in ranges {
                if range.lowerBound > next {
                    gaps.append(next...(range.lowerBound - 1))
                }
                next = range.upperBound + 1
            }
            if next <= 0x10ffff {
                gaps.append(next...0x10ffff)
            }
            return ScalarSet(gaps)
        }

        func union(_ other: ScalarSet) -> ScalarSet {
            ScalarSet(ranges + other.ranges)
        }

        func overlaps(_ other: ScalarSet) -> Bool {
            var index = 0
            var otherIndex = 0
            while index < ranges.count, otherIndex < other.ranges.count {
                if ranges[index].overlaps(other.ranges[otherIndex]) {
                    return true
                }
                if ranges[index].upperBound < other.ranges[otherIndex].upperBound {
                    index += 1
                } else {
                    otherIndex += 1
                }
            }
            return false
        }

        // Every code point written as an escape, apart from ASCII letters, digits and `_`, so that
        // no character means anything to ICU, in a class or out of one.
        var icuPattern: String {
            guard let first = ranges.first else {
                return "[^\\x{0}-\\x{10FFFF}]"
            }
            if ranges.count == 1, first.lowerBound == first.upperBound {
                return Self.icuLiteral(first.lowerBound)
            }
            let items = ranges.map { range in
                range.lowerBound == range.upperBound
                    ? Self.icuLiteral(range.lowerBound)
                    : Self.icuLiteral(range.lowerBound) + "-" + Self.icuLiteral(range.upperBound)
            }
            return "[" + items.joined() + "]"
        }

        private static func icuLiteral(_ value: UInt32) -> String {
            switch value {
            case 0x30...0x39, 0x41...0x5a, 0x5f, 0x61...0x7a:
                return String(Character(Unicode.Scalar(UInt8(value))))
            default:
                return "\\x{" + String(value, radix: 16, uppercase: true) + "}"
            }
        }

        private static func withoutSurrogates(_ range: ClosedRange<UInt32>) -> [ClosedRange<UInt32>] {
            let surrogates: ClosedRange<UInt32> = 0xd800...0xdfff
            guard range.overlaps(surrogates) else { return [range] }
            var parts: [ClosedRange<UInt32>] = []
            if range.lowerBound < surrogates.lowerBound {
                parts.append(range.lowerBound...(surrogates.lowerBound - 1))
            }
            if range.upperBound > surrogates.upperBound {
                parts.append((surrogates.upperBound + 1)...range.upperBound)
            }
            return parts
        }
    }
}

// MARK: - Safety rules

@available(iOS 15.0, macOS 12.0, *)
private extension A2UIRegex.Node {
    // The first of the safety rules 2 to 4 that the pattern breaks. Rule 1, its length, is checked
    // before it is parsed.
    var safetyRejection: A2UIRegex.Rejection? {
        if contains(where: \.repeatsUnboundedRepetition) {
            return A2UIRegex.Rejection(
                code: .nestedQuantifier,
                reason: "it repeats a part that repeats without bound, as in '(a+)+', which can take minutes to match."
            )
        }
        if contains(where: \.repeatsOverlappingAlternation) {
            return A2UIRegex.Rejection(
                code: .overlappingAlternation,
                reason: "it repeats without bound a choice whose options can start with the same character, as in '(a|ab)*', "
                    + "which can take minutes to match."
            )
        }
        if contains(where: \.hasAdjacentOverlap) {
            return A2UIRegex.Rejection(
                code: .adjacentOverlap,
                reason: "two parts next to each other repeat without bound and can match the same character, as in '\\d+\\d+', "
                    + "which can take minutes to match."
            )
        }
        return nil
    }

    // Rule 2: a quantifier whose upper bound is above 1 applies to a subexpression that contains an
    // unbounded quantifier.
    var repeatsUnboundedRepetition: Bool {
        guard case let .repetition(child, repetition) = self else { return false }
        return (repetition.max ?? .max) > 1 && child.contains(where: \.isUnboundedRepetition)
    }

    // Rule 3: an unbounded quantifier applies to an alternation where two branches can start with
    // the same character, comparing the branches without their groups.
    var repeatsOverlappingAlternation: Bool {
        guard case let .repetition(child, repetition) = self, repetition.max == nil,
              case let .alternation(branches) = child.withoutGroups else { return false }
        let firsts = branches.map(\.withoutGroups.firstScalars)
        for (index, first) in firsts.enumerated() where firsts[(index + 1)...].contains(where: { first.overlaps($0) }) {
            return true
        }
        return false
    }

    // Rule 4: two unbounded-quantified atoms with overlapping character sets are adjacent in one
    // concatenation, with only items that can match the empty string between them. A group whose
    // only content is one quantified atom counts as that atom.
    var hasAdjacentOverlap: Bool {
        guard case let .sequence(items) = self else { return false }
        let repeated = items.map { item -> A2UIRegex.ScalarSet? in
            guard case let .repetition(child, repetition) = item.withoutGroups, repetition.max == nil else { return nil }
            return child.allScalars
        }
        for start in items.indices {
            guard let scalars = repeated[start] else { continue }
            for next in (start + 1)..<items.count {
                if let other = repeated[next], scalars.overlaps(other) {
                    return true
                }
                if !items[next].isNullable {
                    break
                }
            }
        }
        return false
    }

    var isUnboundedRepetition: Bool {
        guard case let .repetition(_, repetition) = self else { return false }
        return repetition.max == nil
    }

    var children: [Self] {
        switch self {
        case .empty, .scalars, .assertion:
            return []
        case let .lookahead(child, _), let .group(child, _), let .repetition(child, _):
            return [child]
        case let .sequence(nodes), let .alternation(nodes):
            return nodes
        }
    }

    func contains(where predicate: (Self) -> Bool) -> Bool {
        predicate(self) || children.contains { $0.contains(where: predicate) }
    }

    var withoutGroups: Self {
        guard case let .group(child, _) = self else { return self }
        return child.withoutGroups
    }

    var isNullable: Bool {
        switch self {
        case .empty, .assertion, .lookahead:
            return true
        case .scalars:
            return false
        case let .group(child, _):
            return child.isNullable
        case let .repetition(child, repetition):
            return repetition.min == 0 || child.isNullable
        case let .sequence(nodes):
            return nodes.allSatisfy(\.isNullable)
        case let .alternation(nodes):
            return nodes.contains(where: \.isNullable)
        }
    }

    // The characters a match can start with.
    var firstScalars: A2UIRegex.ScalarSet {
        switch self {
        case .empty, .assertion, .lookahead:
            return .empty
        case let .scalars(set):
            return set
        case let .group(child, _):
            return child.firstScalars
        case let .repetition(child, repetition):
            return repetition.max == 0 ? .empty : child.firstScalars
        case let .sequence(nodes):
            var first = A2UIRegex.ScalarSet.empty
            for node in nodes {
                first = first.union(node.firstScalars)
                if !node.isNullable {
                    break
                }
            }
            return first
        case let .alternation(nodes):
            return nodes.reduce(.empty) { $0.union($1.firstScalars) }
        }
    }

    // The characters a match can hold, leaving out those a lookahead only looks at.
    var allScalars: A2UIRegex.ScalarSet {
        switch self {
        case .empty, .assertion, .lookahead:
            return .empty
        case let .scalars(set):
            return set
        case let .group(child, _):
            return child.allScalars
        case let .repetition(child, repetition):
            return repetition.max == 0 ? .empty : child.allScalars
        case let .sequence(nodes), let .alternation(nodes):
            return nodes.reduce(.empty) { $0.union($1.allScalars) }
        }
    }
}

// MARK: - ICU syntax

@available(iOS 15.0, macOS 12.0, *)
private extension A2UIRegex.Node {
    var icuPattern: String {
        switch self {
        case .empty:
            return ""
        case let .scalars(set):
            return set.icuPattern
        case let .assertion(assertion):
            return assertion.icuPattern
        case let .lookahead(child, isNegative):
            return (isNegative ? "(?!" : "(?=") + child.icuPattern + ")"
        case let .group(child, isCapturing):
            return (isCapturing ? "(" : "(?:") + child.icuPattern + ")"
        case let .sequence(nodes):
            return nodes.map(\.icuPattern).joined()
        case let .alternation(nodes):
            return nodes.map(\.icuPattern).joined(separator: "|")
        case let .repetition(child, repetition):
            let count = repetition.max.map { $0 == repetition.min ? "{\(repetition.min)}" : "{\(repetition.min),\($0)}" }
            return child.icuPattern + (count ?? "{\(repetition.min),}") + (repetition.isLazy ? "?" : "")
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private extension A2UIRegex.Assertion {
    // ICU's `$` also matches before a final line break, and its `\b` counts letters beyond ASCII
    // as word characters.
    var icuPattern: String {
        let word = A2UIRegex.ScalarSet.wordCharacters.icuPattern
        switch self {
        case .start:
            return "\\A"
        case .end:
            return "\\z"
        case .wordBoundary:
            return "(?:(?<=\(word))(?!\(word))|(?<!\(word))(?=\(word)))"
        case .notWordBoundary:
            return "(?:(?<=\(word))(?=\(word))|(?<!\(word))(?!\(word)))"
        }
    }
}

// MARK: - Parser

@available(iOS 15.0, macOS 12.0, *)
private extension A2UIRegex {
    // ECMAScript's Pattern grammar in Unicode mode, without what the dialect leaves out. A pattern
    // has at most `maxPatternLength` code points, which bounds the recursion.
    struct Parser {
        private static let quantifiers: Set<Unicode.Scalar> = ["*", "+", "?", "{"]
        private static let syntaxCharacters: Set<Unicode.Scalar> = ["^", "$", "\\", ".", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|", "/"]

        let scalars: [Unicode.Scalar]
        private var index = 0

        init(scalars: [Unicode.Scalar]) {
            self.scalars = scalars
        }

        mutating func parse() throws -> Node {
            let node = try disjunction()
            // A disjunction stops early only at a `)` that closes no group.
            guard current == nil else {
                throw unsupported("it closes a group it doesn't open.")
            }
            return node
        }

        private var current: Unicode.Scalar? {
            index < scalars.count ? scalars[index] : nil
        }

        private mutating func next() -> Unicode.Scalar? {
            guard let scalar = current else { return nil }
            index += 1
            return scalar
        }

        private mutating func take(_ expected: Unicode.Scalar) -> Bool {
            guard current == expected else { return false }
            index += 1
            return true
        }

        private func unsupported(_ reason: String) -> Rejection {
            Rejection(code: .unsupportedSyntax, reason: reason)
        }

        private mutating func disjunction() throws -> Node {
            var branches = [try alternative()]
            while take("|") {
                branches.append(try alternative())
            }
            return branches.count == 1 ? branches[0] : .alternation(branches)
        }

        private mutating func alternative() throws -> Node {
            var items: [Node] = []
            while let scalar = current, scalar != "|", scalar != ")" {
                items.append(try term())
            }
            switch items.count {
            case 0: return .empty
            case 1: return items[0]
            default: return .sequence(items)
            }
        }

        private mutating func term() throws -> Node {
            let repeated = try atom()
            guard let scalar = current, Self.quantifiers.contains(scalar) else { return repeated }
            switch repeated {
            case .assertion, .lookahead:
                throw unsupported("an assertion such as '^', '$', '\\b' or a lookahead can't be repeated.")
            default:
                index += 1
                let repetition = try quantifier(scalar)
                if let next = current, Self.quantifiers.contains(next) {
                    throw unsupported("a quantifier can't follow another, as in 'a**' or 'a++'.")
                }
                return .repetition(repeated, repetition)
            }
        }

        private mutating func atom() throws -> Node {
            guard let scalar = next() else {
                throw unsupported("it ends too early.")
            }
            switch scalar {
            case "^":
                return .assertion(.start)
            case "$":
                return .assertion(.end)
            case ".":
                return .scalars(.dot)
            case "(":
                return try group()
            case "[":
                return try characterClass()
            case "\\":
                return try atomEscape()
            case "*", "+", "?", "{":
                throw unsupported("'\(scalar)' has nothing to repeat; write '\\\(scalar)' to match the character.")
            case "]", "}":
                throw unsupported("a '\(scalar)' on its own must be written '\\\(scalar)'.")
            default:
                return .scalars(ScalarSet(scalar))
            }
        }

        private mutating func group() throws -> Node {
            guard take("?") else {
                return .group(try groupBody(), isCapturing: true)
            }
            switch next() {
            case ":":
                return .group(try groupBody(), isCapturing: false)
            case "=":
                return .lookahead(try groupBody(), isNegative: false)
            case "!":
                return .lookahead(try groupBody(), isNegative: true)
            case "<":
                throw unsupported(current == "=" || current == "!" ? "lookbehind isn't allowed." : "named groups aren't allowed.")
            default:
                throw unsupported("inline flags and other '(?' groups aren't allowed.")
            }
        }

        private mutating func groupBody() throws -> Node {
            let body = try disjunction()
            guard take(")") else {
                throw unsupported("it opens a group it doesn't close.")
            }
            return body
        }

        private mutating func quantifier(_ scalar: Unicode.Scalar) throws -> Repetition {
            let bounds: (min: Int, max: Int?)
            switch scalar {
            case "*":
                bounds = (0, nil)
            case "+":
                bounds = (1, nil)
            case "?":
                bounds = (0, 1)
            default:
                let lower = try count()
                var upper: Int? = lower
                if take(",") {
                    upper = nil
                    if current != "}" {
                        upper = try count()
                    }
                }
                guard take("}") else {
                    throw unsupported("a '{' must start a count such as '{2}', '{2,}' or '{2,5}', or be written '\\{'.")
                }
                guard lower <= maxCount, upper ?? 0 <= maxCount else {
                    throw unsupported("a count can't be above \(maxCount).")
                }
                if let upper, upper < lower {
                    throw unsupported("the count '{\(lower),\(upper)}' is out of order.")
                }
                bounds = (lower, upper)
            }
            return Repetition(min: bounds.min, max: bounds.max, isLazy: take("?"))
        }

        // Capped just above `maxCount`, so that a long run of digits can't overflow.
        private mutating func count() throws -> Int {
            let start = index
            var value = 0
            while let scalar = current, let digit = Self.digit(scalar, radix: 10) {
                value = min(value * 10 + Int(digit), maxCount + 1)
                index += 1
            }
            guard index > start else {
                throw unsupported("a '{' must start a count such as '{2}', '{2,}' or '{2,5}', or be written '\\{'.")
            }
            return value
        }

        private mutating func atomEscape() throws -> Node {
            guard let escaped = next() else {
                throw unsupported("it ends with a lone backslash.")
            }
            switch escaped {
            case "b":
                return .assertion(.wordBoundary)
            case "B":
                return .assertion(.notWordBoundary)
            default:
                if let set = ScalarSet.classEscape(escaped) {
                    return .scalars(set)
                }
                return .scalars(ScalarSet(try characterEscape(escaped, inClass: false)))
            }
        }

        // The character an escape other than a class escape such as `\d` stands for.
        private mutating func characterEscape(_ escaped: Unicode.Scalar, inClass: Bool) throws -> Unicode.Scalar {
            switch escaped {
            case "t": return "\t"
            case "n": return "\n"
            case "v": return "\u{0B}"
            case "f": return "\u{0C}"
            case "r": return "\r"
            case "0":
                if let next = current, Self.digit(next, radix: 10) != nil {
                    throw unsupported("legacy octal escapes such as '\\0\(next)' aren't allowed.")
                }
                return "\0"
            case "1"..."9":
                throw unsupported("backreferences such as '\\\(escaped)' aren't allowed.")
            case "k":
                throw unsupported("backreferences such as '\\k<name>' aren't allowed.")
            case "p", "P":
                throw unsupported("Unicode property escapes such as '\\\(escaped){L}' aren't allowed.")
            case "c":
                throw unsupported("control escapes such as '\\cA' aren't allowed.")
            case "x":
                return try scalar(try hexDigits(2))
            case "u":
                return try unicodeEscape()
            case "-" where inClass:
                return "-"
            default:
                guard Self.syntaxCharacters.contains(escaped) else {
                    throw unsupported("'\\\(escaped)' isn't an escape the dialect allows.")
                }
                return escaped
            }
        }

        // `\uHHHH`, a pair of them for a surrogate pair, or `\u{H…}`.
        private mutating func unicodeEscape() throws -> Unicode.Scalar {
            guard take("{") else {
                let value = try hexDigits(4)
                let start = index
                if (0xd800...0xdbff).contains(value), take("\\"), take("u"),
                   let low = try? hexDigits(4), (0xdc00...0xdfff).contains(low) {
                    return try scalar(0x10000 + ((value - 0xd800) << 10) + (low - 0xdc00))
                }
                index = start
                return try scalar(value)
            }
            var value: UInt32 = 0
            var digits = 0
            while let next = current, next != "}" {
                guard let digit = Self.digit(next, radix: 16) else {
                    throw unsupported("a '\\u{…}' escape holds only hexadecimal digits.")
                }
                value = value * 16 + digit
                guard value <= 0x10ffff else {
                    throw unsupported("a '\\u{…}' escape can't be above 10FFFF.")
                }
                digits += 1
                index += 1
            }
            guard digits > 0, take("}") else {
                throw unsupported("a '\\u{…}' escape needs hexadecimal digits and a closing '}'.")
            }
            return try scalar(value)
        }

        private mutating func hexDigits(_ count: Int) throws -> UInt32 {
            var value: UInt32 = 0
            for _ in 0..<count {
                guard let next = current, let digit = Self.digit(next, radix: 16) else {
                    throw unsupported("'\\x' takes two hexadecimal digits, and '\\u' four.")
                }
                value = value * 16 + digit
                index += 1
            }
            return value
        }

        private func scalar(_ value: UInt32) throws -> Unicode.Scalar {
            guard let scalar = Unicode.Scalar(value) else {
                throw unsupported("an escape can't stand for a lone surrogate such as D800.")
            }
            return scalar
        }

        private mutating func characterClass() throws -> Node {
            let isNegated = take("^")
            var ranges: [ClosedRange<UInt32>] = []
            while let scalar = current, scalar != "]" {
                let low = try classAtom()
                guard current == "-", index + 1 < scalars.count, scalars[index + 1] != "]" else {
                    ranges.append(contentsOf: low.ranges)
                    continue
                }
                index += 1
                if current == "-" {
                    throw unsupported("class subtraction such as '[a--b]' isn't allowed.")
                }
                guard case let .scalar(lower) = low, case let .scalar(upper) = try classAtom() else {
                    throw unsupported("a class escape such as '\\d' can't start or end a range.")
                }
                guard lower <= upper else {
                    throw unsupported("the range '\(lower)-\(upper)' is out of order.")
                }
                ranges.append(lower.value...upper.value)
            }
            guard take("]") else {
                throw unsupported("it opens a character class it doesn't close.")
            }
            guard !ranges.isEmpty else {
                throw unsupported("an empty character class such as '[]' or '[^]' isn't allowed.")
            }
            let set = ScalarSet(ranges)
            return .scalars(isNegated ? set.inverted : set)
        }

        private enum ClassAtom {
            case scalar(Unicode.Scalar)
            case set(ScalarSet)

            var ranges: [ClosedRange<UInt32>] {
                switch self {
                case let .scalar(scalar): return [scalar.value...scalar.value]
                case let .set(set): return set.ranges
                }
            }
        }

        private mutating func classAtom() throws -> ClassAtom {
            guard let scalar = next() else {
                throw unsupported("it opens a character class it doesn't close.")
            }
            switch scalar {
            case "[":
                throw unsupported("a '[' in a character class, as in '[[:alpha:]]' or a nested class, must be written '\\['.")
            case "&" where current == "&":
                throw unsupported("class intersection such as '[a&&b]' isn't allowed.")
            case "\\":
                guard let escaped = next() else {
                    throw unsupported("it ends with a lone backslash.")
                }
                switch escaped {
                case "b":
                    return .scalar("\u{08}")
                case "B":
                    throw unsupported("'\\B' isn't allowed in a character class.")
                default:
                    if let set = ScalarSet.classEscape(escaped) {
                        return .set(set)
                    }
                    return .scalar(try characterEscape(escaped, inClass: true))
                }
            default:
                return .scalar(scalar)
            }
        }

        // The value of an ASCII digit in base 10 or 16.
        private static func digit(_ scalar: Unicode.Scalar, radix: UInt32) -> UInt32? {
            switch scalar.value {
            case 0x30...0x39:
                return scalar.value - 0x30
            case 0x41...0x46 where radix == 16:
                return scalar.value - 0x41 + 10
            case 0x61...0x66 where radix == 16:
                return scalar.value - 0x61 + 10
            default:
                return nil
            }
        }
    }
}
