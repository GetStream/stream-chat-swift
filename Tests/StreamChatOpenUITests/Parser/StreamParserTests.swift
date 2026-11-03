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
        let setChunks = Self.chunks(of: Self.largeProgram, size: 10)
        let pushChunks = Self.chunks(of: Self.largeProgram, size: 25)
        var setParser = library.makeStreamParser()
        var pushParser = library.makeStreamParser()
        var text = ""
        var setResult: ParseResult?
        var pushResult: ParseResult?

        for (index, chunk) in setChunks.enumerated() {
            text += chunk
            setResult = setParser.set(text, complete: index == setChunks.count - 1)
        }
        for (index, chunk) in pushChunks.enumerated() {
            pushResult = pushParser.push(chunk, complete: index == pushChunks.count - 1)
        }

        let whole = library.parser.parse(Self.largeProgram)
        #expect(whole.root?.props["children"]?.arrayValue?.count == 231)
        #expect(setResult == whole)
        #expect(pushResult == whole)
        let bytes = Self.largeProgram.utf8.count
        #expect(setParser.preprocessedBytes < 40 * bytes, "each chunk reads its own bytes and the line it ends")
        #expect(pushParser.preprocessedBytes < 40 * bytes)
        // Each chunk materializes the root's list of references and the statement still
        // arriving, and reuses the statements before it, rather than the whole program.
        #expect(setParser.materializedNodes < 2 * whole.meta.statementCount * setChunks.count)
        #expect(pushParser.materializedNodes < 2 * whole.meta.statementCount * pushChunks.count)
    }

    static func lines(_ range: ClosedRange<Int>, _ line: (Int) -> String) -> String {
        range.map(line).joined(separator: "\n")
    }

    static let deepChain = [
        "root = Card([x, p, d1])",
        "p = Card([x])",
        lines(1...60) { "d\($0) = Card([d\($0 + 1)])" },
        "d61 = Card([p])",
        lines(1...30) { "x\($0 == 1 ? "" : String($0)) = Card([x\($0 + 1)])" },
        #"x31 = TextContent("end")"#
    ].joined(separator: "\n")

    static let reusedStatements: [(program: String, chunkSize: Int)] = [
        // Declared after use, and declared again.
        (#"root = Card([a, b])\#na = TextContent("one")\#nb = TextContent($t)\#na = TextContent("two")\#n$t = "x""#, 3),
        // A cycle, cut where `b` is reached through `a` but not where `c` reaches it.
        (#"root = Card([a, c])\#na = Card([b])\#nb = Card([a, TextContent("x")])\#nc = Card([b])"#, 3),
        // `p`, and the `x` it uses, fit where the root uses them, but not at the end of the deep chain.
        (deepChain, 60),
        // Each `e` fits the node budget, but not all of them.
        (#"a0 = TextContent("x")\#n"# + lines(1...13) { "a\($0) = [a\($0 - 1), a\($0 - 1)]" } + "\ne = [a13]\nroot = Card([e, e, e, e, e, e, e])", 40),
        (#"root = Card([CardHeader($title), list])\#n$title = "Hi"\#nlist = Card([TextContent($title), Button("Go", @Set($title, "Bye"))])"#, 2)
    ]

    // A parser fed the text a chunk at a time reuses what statements materialized to before; one
    // fed all of it at once can't, so the two agree only if reusing changes nothing. The deep
    // chain needs the main thread's stack, as the runtime has.
    @MainActor
    @Test(arguments: reusedStatements.indices)
    func reusedStatementsReadAsTheyDoFresh(_ index: Int) {
        let (program, chunkSize) = Self.reusedStatements[index]
        let library = ComponentLibrary.openUIChat
        var streaming = library.makeStreamParser()
        var text = ""

        for chunk in Self.chunks(of: program, size: chunkSize) {
            text += chunk
            var fresh = library.makeStreamParser()
            let streamed = streaming.set(text)
            let whole = fresh.set(text)
            guard streamed == whole else {
                Issue.record("\(text.debugDescription) streams differently")
                return
            }
        }
        // Parsed at once, nothing is reused; only the count of statements read twice differs.
        var streamed = streaming.set(program, complete: true)
        let whole = library.parser.parse(program)
        streamed.meta.statementCount = whole.meta.statementCount
        #expect(streamed == whole)
    }
}
