//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

/// Differential tests against the reference TypeScript implementation (`@openuidev/lang-core`).
///
/// `Fixtures/parser-conformance.json` was produced by running the upstream parser over a corpus of
/// programs (every example from the OpenUI docs and prompt examples, the benchmark samples, and
/// hand-written edge cases). Each case records the one-shot `parse()` result and snapshots of the
/// streaming parser while the input is pushed in pseudo-random chunks.
@Suite("Parser conformance with the reference implementation")
struct ParserConformanceTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let library: String
        let input: String
        let result: OpenUIValue
        let chunks: [String]
        let checkpoints: [Int]
        let streamResults: [OpenUIValue]
        let completeResult: OpenUIValue

        var testDescription: String { name }
    }

    static let cases: [Case] = {
        guard case .array(let items)? = try? Fixtures.json("parser-conformance.json") else { return [] }
        return items.compactMap { item in
            guard let name = item["name"]?.stringValue,
                  let library = item["library"]?.stringValue,
                  let input = item["input"]?.stringValue,
                  let result = item["result"],
                  let chunks = item["chunks"]?.arrayValue?.compactMap(\.stringValue),
                  let checkpoints = item["checkpoints"]?.arrayValue?.compactMap(\.numberValue),
                  let streamResults = item["streamResults"]?.arrayValue,
                  let completeResult = item["completeResult"] else { return nil }
            return Case(
                name: name,
                library: library,
                input: input,
                result: result,
                chunks: chunks,
                checkpoints: checkpoints.map { Int($0) },
                streamResults: streamResults,
                completeResult: completeResult
            )
        }
    }()

    static let libraries: [String: (ParamMap, String?)] = {
        var result: [String: (ParamMap, String?)] = [:]
        for (name, file) in [("chat", "upstream-chat-library.spec.json"), ("playground", "upstream-playground-library.spec.json")] {
            if let spec = try? Fixtures.json(file), let schema = spec["schema"] {
                result[name] = (OpenUIParser.compileSchema(schema), spec["root"]?.stringValue)
            }
        }
        let mini: OpenUIValue = [
            "$defs": [
                "Stack": ["properties": ["children": [:]], "required": ["children"]],
                "Title": ["properties": ["text": ["type": "string"]], "required": ["text"]]
            ]
        ]
        result["mini"] = (OpenUIParser.compileSchema(mini), nil)
        if let spec = try? Fixtures.json("spec-library.json"), let schema = spec["schema"] {
            result["spec"] = (OpenUIParser.compileSchema(schema), spec["root"]?.stringValue)
        }
        return result
    }()

    @Test func fixturesAreLoaded() {
        #expect(Self.cases.count >= 190)
        #expect(Self.libraries.count == 4)
    }

    @Test(arguments: cases)
    func completedStreamMatchesReference(_ testCase: Case) throws {
        let (paramMap, rootName) = try #require(Self.libraries[testCase.library])
        var parser = OpenUIStreamParser(paramMap: paramMap, rootName: rootName)
        var result = parser.result(complete: true)
        for (step, chunk) in testCase.chunks.enumerated() {
            result = parser.push(chunk, complete: step == testCase.chunks.count - 1)
        }
        let difference = firstDifference(result.jsonValue, testCase.completeResult)
        #expect(difference == nil, "\(testCase.name): \(difference ?? "")")
    }

    @Test(arguments: cases)
    func oneShotParseMatchesReference(_ testCase: Case) throws {
        let (paramMap, rootName) = try #require(Self.libraries[testCase.library])
        let actual = OpenUIParser(paramMap: paramMap, rootName: rootName).parse(testCase.input).jsonValue
        let difference = firstDifference(actual, testCase.result)
        #expect(difference == nil, "\(testCase.name): \(difference ?? "")")
    }

    @Test(arguments: cases)
    func streamingParseMatchesReference(_ testCase: Case) throws {
        let (paramMap, rootName) = try #require(Self.libraries[testCase.library])
        var parser = OpenUIStreamParser(paramMap: paramMap, rootName: rootName)
        var checkpointIndex = 0
        for (step, chunk) in testCase.chunks.enumerated() {
            let result = parser.push(chunk)
            guard checkpointIndex < testCase.checkpoints.count, testCase.checkpoints[checkpointIndex] == step else { continue }
            let difference = firstDifference(result.jsonValue, testCase.streamResults[checkpointIndex])
            #expect(difference == nil, "\(testCase.name) @ step \(step): \(difference ?? "")")
            if difference != nil { return }
            checkpointIndex += 1
        }
        #expect(checkpointIndex == testCase.checkpoints.count)
    }
}
