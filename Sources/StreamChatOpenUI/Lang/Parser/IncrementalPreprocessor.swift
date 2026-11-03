//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// `Preprocessor.preprocess` of text that only grows at the end. Each `append` reads the bytes
// added since the last one, and redoes only the last line, which later bytes can still change.
@available(iOS 17.0, macOS 14.0, *)
struct IncrementalPreprocessor: Sendable {
    // The preprocessed text is `bytes[0..<count]`. Everything up to its last line break stays the
    // same as text is appended, unless `append` reports that it started over.
    private(set) var bytes: [UInt8] = []
    private(set) var count = 0
    // How many bytes all appends have read, which grows with the text, not with its square.
    private(set) var bytesRead = 0

    private var fences = FenceStripper()
    private var comments = CommentStripper()
    // How many of `bytes` won't change, and where the last non-whitespace among them ends.
    private var committed = 0
    private var committedContentEnd = 0
    private var keptContent = false

    // Returns true when the text so far reads differently, which a fence after unfenced text
    // causes: only what is inside fences is kept from then on.
    mutating func append(_ raw: some Collection<UInt8>) -> Bool {
        bytesRead += raw.count
        let (startedOver, stripped) = fences.feed(raw)
        if startedOver {
            comments = CommentStripper()
            bytes.removeAll()
            committed = 0
            committedContentEnd = 0
            keptContent = false
        }
        bytes.removeSubrange(committed...)
        commit(comments.feed(stripped))
        bytesRead += comments.lastLineCount + fences.undecided.count
        let lastLine = trimmedStart(comments.lastLine(followedBy: fences.undecided))
        bytes.append(contentsOf: lastLine)
        count = Self.contentEnd(lastLine).map { committed + $0 } ?? committedContentEnd
        return startedOver
    }

    private mutating func commit(_ lines: [UInt8]) {
        let kept = trimmedStart(lines)
        guard !kept.isEmpty else { return }
        keptContent = true
        if let end = Self.contentEnd(kept) {
            committedContentEnd = committed + end
        }
        bytes.append(contentsOf: kept)
        committed += kept.count
    }

    // Leading whitespace is trimmed until the first byte of content is kept.
    private func trimmedStart(_ text: [UInt8]) -> ArraySlice<UInt8> {
        keptContent ? text[...] : text.dropFirst(Self.leadingWhitespace(text))
    }

    private static func leadingWhitespace(_ text: [UInt8]) -> Int {
        var length = 0
        for scalar in String(decoding: text, as: UTF8.self).unicodeScalars {
            guard JS.isWhitespace(scalar) else { break }
            length += UTF8.width(scalar)
        }
        return length
    }

    // Where the last scalar that isn't whitespace ends, or nil when there is none.
    private static func contentEnd(_ text: some Collection<UInt8>) -> Int? {
        var offset = 0
        var end: Int?
        for scalar in String(decoding: text, as: UTF8.self).unicodeScalars {
            offset += UTF8.width(scalar)
            if !JS.isWhitespace(scalar) { end = offset }
        }
        return end
    }
}

// `Preprocessor.stripFences`, one byte at a time: before any fence the text is kept as it is,
// and once one is found only the text inside fences is.
@available(iOS 17.0, macOS 14.0, *)
private struct FenceStripper: Sendable {
    private enum Place {
        case outside
        case language
        case content
    }

    private enum Quote {
        case none
        case open
        case escaped
    }

    private static let backtick = UInt8(ascii: "`")
    private static let doubleQuote = UInt8(ascii: "\"")
    private static let backslash = UInt8(ascii: "\\")
    private static let newline = UInt8(ascii: "\n")

    private var fenced = false
    private var place = Place.outside
    private var quote = Quote.none
    private var blocks = 0
    // One or two backticks at the end, which a fence needs the next bytes to tell apart.
    private var pending: [UInt8] = []

    // What the undecided backticks read as if the text ended here: text, unless they are
    // outside fences, which drop text.
    var undecided: [UInt8] {
        !fenced || place == .content ? pending : []
    }

    mutating func feed(_ raw: some Sequence<UInt8>) -> (startedOver: Bool, output: [UInt8]) {
        var input = pending
        input.append(contentsOf: raw)
        pending = []
        var output: [UInt8] = []
        var startedOver = false
        var index = 0
        while index < input.count {
            let byte = input[index]
            if place == .language {
                if byte == Self.newline {
                    place = .content
                    quote = .none
                }
                index += 1
                continue
            }
            if quote == .none, byte == Self.backtick {
                guard let isFence = Self.fence(at: index, in: input) else {
                    pending = Array(input[index...])
                    break
                }
                if isFence {
                    if !fenced {
                        fenced = true
                        startedOver = true
                        output.removeAll()
                    }
                    if place == .content {
                        place = .outside
                    } else {
                        blocks += 1
                        if blocks > 1 { output.append(Self.newline) }
                        place = .language
                    }
                    index += 3
                    continue
                }
            }
            switch quote {
            case .escaped:
                quote = .open
            case .open:
                if byte == Self.backslash {
                    quote = .escaped
                } else if byte == Self.doubleQuote {
                    quote = .none
                }
            case .none:
                if byte == Self.doubleQuote { quote = .open }
            }
            if !fenced || place == .content { output.append(byte) }
            index += 1
        }
        return (startedOver, output)
    }

    // Whether three backticks start at `index`, or nil when the text ends before that's known.
    private static func fence(at index: Int, in input: [UInt8]) -> Bool? {
        if index + 1 < input.count, input[index + 1] != backtick { return false }
        guard index + 2 < input.count else { return nil }
        return input[index + 2] == backtick
    }
}

// `Preprocessor.stripComments`, a line at a time.
@available(iOS 17.0, macOS 14.0, *)
private struct CommentStripper: Sendable {
    private static let newline = UInt8(ascii: "\n")

    // The string open where the last line starts, and that line so far.
    private var quote: UInt8?
    private var line: [UInt8] = []

    var lastLineCount: Int {
        line.count
    }

    // The lines the input completes, each with its line break.
    mutating func feed(_ input: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        var start = 0
        for index in input.indices where input[index] == Self.newline {
            line.append(contentsOf: input[start..<index])
            output.append(contentsOf: Self.strip(line, quote: &quote))
            output.append(Self.newline)
            line.removeAll(keepingCapacity: true)
            start = index + 1
        }
        line.append(contentsOf: input[start...])
        return output
    }

    // The last line, which no line break ends yet, as it reads if `rest` ends the text.
    func lastLine(followedBy rest: [UInt8]) -> [UInt8] {
        var quote = self.quote
        return Self.strip(line + rest, quote: &quote)
    }

    private static func strip(_ line: [UInt8], quote: inout UInt8?) -> [UInt8] {
        var index = 0
        while index < line.count {
            let byte = line[index]
            if let open = quote {
                if byte == UInt8(ascii: "\\"), index + 1 < line.count {
                    index += 2
                    continue
                }
                if byte == open { quote = nil }
                index += 1
                continue
            }
            if byte == UInt8(ascii: "\"") || byte == UInt8(ascii: "'") {
                quote = byte
            } else if (byte == UInt8(ascii: "/") && index + 1 < line.count && line[index + 1] == UInt8(ascii: "/")) || byte == UInt8(ascii: "#") {
                return Array(JS.trimEnd(String(decoding: line[..<index], as: UTF8.self)).utf8)
            }
            index += 1
        }
        return line
    }
}
