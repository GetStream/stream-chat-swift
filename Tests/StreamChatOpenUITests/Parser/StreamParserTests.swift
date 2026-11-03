//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@Suite("Streaming parser")
struct StreamParserTests {
    // A fixed sequence of random numbers, so a failure repeats.
    struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    static let pieces = [
        "`", "``", "```", "```js\n", "```\n", "\"", "'", "\\", "/", "//", "#", "\n", "\r\n", " ", "\t", "\u{00A0}", "\u{3000}",
        "é", "a", "x = 1", "(", ")", "[", "]", "?", ":", "root = Stack([a])", "a = TextContent(\"hi\")", "$x"
    ]

    @Test func preprocessingAppendedTextMatchesPreprocessingItWhole() {
        var generator = SeededGenerator(state: 0x9e3779b97f4a7c15)
        for _ in 0..<1000 {
            var text = ""
            var preprocessor = IncrementalPreprocessor()
            var stable: [UInt8] = []
            for _ in 0..<Int.random(in: 1...30, using: &generator) {
                let piece = Self.pieces.randomElement(using: &generator) ?? ""
                text += piece
                let startedOver = preprocessor.append(piece.utf8)
                let preprocessed = Array(preprocessor.bytes[0..<preprocessor.count])

                guard preprocessed == Array(Preprocessor.preprocess(text).utf8) else {
                    Issue.record("\(text.debugDescription) reads as \(String(decoding: preprocessed, as: UTF8.self).debugDescription)")
                    return
                }
                guard startedOver || preprocessor.bytes.starts(with: stable) else {
                    Issue.record("\(text.debugDescription) changed text before its last line")
                    return
                }
                stable = preprocessed.lastIndex(of: 0x0a).map { Array(preprocessed[...$0]) } ?? (startedOver ? [] : stable)
            }
        }
    }

    // About 50 KB in a fence, with comments, state and one card per line.
    static let largeProgram: String = {
        var lines = ["```openui", "// A long list", "root = Card([title, " + (0..<230).map { "s\($0)" }.joined(separator: ", ") + "])"]
        lines.append(#"title = CardHeader("Items", $filter)"#)
        lines.append(#"$filter = "all""#)
        for index in 0..<230 {
            lines.append(
                #"s\#(index) = Card([CardHeader("Item \#(index)", "Subtitle \#(index)"), TextContent("Body text for item \#(index), long enough to look like a real one."), Buttons([Button("Open", @ToAssistant("open \#(index)"))])]) // card \#(index)"#
            )
        }
        lines.append("```")
        return lines.joined(separator: "\n")
    }()

    static func chunks(of text: String, size: Int) -> [String] {
        let characters = Array(text)
        return stride(from: 0, to: characters.count, by: size).map { String(characters[$0..<min($0 + size, characters.count)]) }
    }

    @Test func streamingALargeProgramInSmallChunksMatchesParsingItAtOnce() {
        let library = ComponentLibrary.openUIChat
        let chunks = Self.chunks(of: Self.largeProgram, size: 10)
        var setParser = library.makeStreamParser()
        var pushParser = library.makeStreamParser()
        var text = ""
        var setResult: ParseResult?
        var pushResult: ParseResult?

        for (index, chunk) in chunks.enumerated() {
            text += chunk
            setResult = setParser.set(text, complete: index == chunks.count - 1)
            pushResult = pushParser.push(chunk, complete: index == chunks.count - 1)
        }

        let whole = library.parser.parse(Self.largeProgram)
        #expect(whole.root?.props["children"]?.arrayValue?.count == 231)
        #expect(setResult == whole)
        #expect(pushResult == whole)
        let bytes = Self.largeProgram.utf8.count
        #expect(setParser.preprocessedBytes < 40 * bytes, "each chunk reads its own bytes and the line it ends")
        #expect(pushParser.preprocessedBytes < 40 * bytes)
    }
}
