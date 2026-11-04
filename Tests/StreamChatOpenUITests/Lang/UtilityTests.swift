//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

@Suite("JavaScript semantics")
struct JSCompatTests {
    @Test(arguments: [
        (0.0, "0"), (-0.0, "0"), (1.0, "1"), (-1.5, "-1.5"), (0.1 + 0.2, "0.30000000000000004"),
        (1e21, "1e+21"), (1e20, "100000000000000000000"), (123_456_789_012_345_680_000.0, "123456789012345680000"),
        (1e-7, "1e-7"), (0.000001, "0.000001"), (1.5e-10, "1.5e-10"), (2e5, "200000"), (1 / 3.0, "0.3333333333333333"),
        (Double.nan, "NaN"), (Double.infinity, "Infinity"), (-Double.infinity, "-Infinity"), (5e-324, "5e-324")
    ])
    func numberToString(_ value: Double, _ expected: String) {
        #expect(JS.numberToString(value) == expected)
    }

    @Test func stringToNumber() {
        #expect(JS.stringToNumber("") == 0)
        #expect(JS.stringToNumber("  12  ") == 12)
        #expect(JS.stringToNumber("0x10") == 16)
        #expect(JS.stringToNumber("0b101") == 5)
        #expect(JS.stringToNumber("1e3") == 1000)
        #expect(JS.stringToNumber(".5") == 0.5)
        #expect(JS.stringToNumber("5.") == 5)
        #expect(JS.stringToNumber("-Infinity") == -.infinity)
        #expect(JS.stringToNumber("12px").isNaN)
        #expect(JS.stringToNumber("-0x10").isNaN)
        #expect(JS.stringToNumber("inf").isNaN)
        #expect(JS.parseFloat("12px") == 12)
        #expect(JS.parseFloat("  3.5e2xyz") == 350)
        #expect(JS.parseFloat("abc").isNaN)
        #expect(JS.parseFloat("1e") == 1)
    }

    @Test func looseEquality() {
        #expect(JS.looseEquals(5, "5"))
        #expect(JS.looseEquals(0, ""))
        #expect(!JS.looseEquals(.null, 0))
        #expect(JS.looseEquals(.null, nil))
        #expect(JS.looseEquals(true, "1"))
        #expect(!JS.looseEquals(true, "true"))
        #expect(JS.looseEquals([1], 1))
        #expect(JS.looseEquals("", []))
        #expect(!JS.looseEquals(.number(.nan), .number(.nan)))
    }

    @Test func conversions() {
        #expect(JS.toString([1, .null, "a"]) == "1,,a")
        #expect(JS.toString(["a": 1]) == "[object Object]")
        #expect(JS.isTruthy("0"))
        #expect(!JS.isTruthy(0))
        #expect(!JS.isTruthy(""))
        #expect(JS.isTruthy([]))
        #expect(JS.round(2.5) == 3)
        #expect(JS.round(-2.5) == -2)
        #expect(JS.round(0.49999999999999994) == 0)
        #expect(JS.jsonStringify(["a": "x\"y\n", "b": [1.5, .null, true]]) == #"{"a":"x\"y\n","b":[1.5,null,true]}"#)
        #expect(JS.property(of: "héllo", key: "length") == 5)
        #expect(JS.property(of: [1, 2], key: "1") == 2)
        #expect(JS.property(of: [1, 2], key: "01") == nil)
    }

    @Test func jsonParsingPreservesKeyOrder() throws {
        let value = try OpenUIJSON.parse(#"{"z": 1, "a": {"y": [1, 2.5e1, -0.5], "b": "é😀"}, "m": null}"#)
        #expect(value.objectValue?.keys == ["z", "a", "m"])
        #expect(value["a"]?["y"] == [1, 25, -0.5])
        #expect(value["a"]?["b"] == "é😀")
        #expect(throws: OpenUIJSONError.self) { try OpenUIJSON.parse("{\"a\": 1,}") }
        #expect(throws: OpenUIJSONError.self) { try OpenUIJSON.parse("\"raw\nnewline\"") }
    }
}

@Suite("Form validation")
struct FormValidationTests {
    @Test func parsesRules() {
        #expect(FormValidation.parseRules(["required", "min:8", "pattern:^[a-z]+$", 5]) == [
            ValidationRule(type: "required"),
            ValidationRule(type: "min", argument: 8),
            ValidationRule(type: "pattern", argument: "^[a-z]+$")
        ])
        #expect(FormValidation.parseStructuredRules(["required": true, "email": false, "minLength": 3]) == [
            ValidationRule(type: "required"),
            ValidationRule(type: "minLength", argument: 3)
        ])
    }

    @Test func validators() {
        func check(_ value: OpenUIValue?, _ rules: OpenUIValue) -> String? {
            FormValidation.validate(value, rules: FormValidation.rules(from: rules))
        }
        #expect(check(nil, ["required": true]) == "This field is required")
        #expect(check("", ["required": true]) == "This field is required")
        #expect(check(["a": false, "b": false], ["required": true]) == "At least one option is required")
        #expect(check(["a": true], ["required": true]) == nil)
        #expect(check("nope", ["email": true]) == "Please enter a valid email")
        #expect(check("me@example.com", ["email": true]) == nil)
        #expect(check("abc", ["minLength": 5]) == "Must be at least 5 characters")
        #expect(check("7", ["min": 10]) == "Must be at least 10")
        #expect(check("12", ["max": 10]) == "Must be no more than 10")
        #expect(check("12a", ["numeric": true]) == nil, "parseFloat semantics")
        #expect(check("abc", ["numeric": true]) == "Must be a number")
        #expect(check("ABC", ["pattern": "^[a-z]+$"]) == "Invalid format")
        #expect(check("not a url", ["url": true]) == "Please enter a valid URL")
        #expect(check("https://openui.com", ["url": true]) == nil)
        #expect(check("", ["email": true, "minLength": 3]) == nil, "empty optional fields pass")
    }
}

@Suite("Message envelope")
struct MessageEnvelopeTests {
    @Test func buildsAndParsesContentContextAndAttributes() {
        let message = MessageEnvelope.build(
            content: "Submit",
            context: ["User clicked: Submit", ["form": ["a": 1]]],
            attributes: ["library": "chat ui", "v": "1&2"],
            end: true
        )
        #expect(message == "]]>openui:content?library=chat+ui&v=1%262\nSubmit\n]]>openui:context\n[\"User clicked: Submit\",{\"form\":{\"a\":1}}]\n]]>openui:end")

        let parsed = MessageEnvelope.parse(message)

        #expect(parsed.content == "Submit")
        #expect(parsed.context == ["User clicked: Submit", ["form": ["a": 1]]])
        #expect(parsed.attributes == ["library": "chat ui", "v": "1&2"])
        #expect(parsed.isEnded)
    }

    @Test func aStringContextIsWrittenAsIsAndNonJSONContextReadsAsText() {
        let message = MessageEnvelope.build(content: "x", context: "not json")

        #expect(message == "]]>openui:content\nx\n]]>openui:context\nnot json")
        #expect(MessageEnvelope.parse(message).context == "not json")
        #expect(MessageEnvelope.build(content: "x", context: .null) == "]]>openui:content\nx")
    }

    @Test func plainAndLegacyMessagesRead() {
        #expect(MessageEnvelope.parse("root = Card([])").content == "root = Card([])")
        #expect(MessageEnvelope.parse("root = Card([])").context == nil)
        let legacy = MessageEnvelope.parse("<content>root = Card([])</content><context>[1]</context>")
        #expect(legacy.content == "root = Card([])")
        #expect(legacy.context == [1])
        #expect(MessageEnvelope.hasLangSyntax("text\nroot = Card([])"))
        #expect(!MessageEnvelope.hasLangSyntax("plain markdown"))
    }

    @Test func aCompleteMessageKeepsContentEndingInABracket() {
        #expect(MessageEnvelope.parse("]]>openui:content\ncols = [\"a\", \"b\"]").content == "cols = [\"a\", \"b\"]")
        #expect(MessageEnvelope.parse("text [1]").content == "text [1]")
    }

    @Test func streamingHoldsBackAMarkerCutMidLine() {
        #expect(MessageEnvelope.parse("]]>openui:content\nroot = Card([])\n]]>openui:con", isStreaming: true).content == "root = Card([])")
        #expect(MessageEnvelope.parse("]]>openui:content\nroot = Card([])\nmore").content == "root = Card([])\nmore")
        #expect(MessageEnvelope.parse("]]>openui:content\nroot = Card([]) ]]>openui:con", isStreaming: true).content == "root = Card([]) ")
    }

    @Test func aRegeneratedResponseWins() {
        let message = "]]>openui:content\nroot = Card([cut]]>openui:content\nroot = Card([])\n]]>openui:end"

        let parsed = MessageEnvelope.parse(message)

        #expect(parsed.content == "root = Card([])")
        #expect(parsed.isEnded)
    }

    @Test func anEndMarkerMidLineStaysInTheContent() {
        let parsed = MessageEnvelope.parse("]]>openui:content\nhello ]]>openui:end there")

        #expect(parsed.content == "hello ]]>openui:end there")
        #expect(!parsed.isEnded)
    }

    @Test func contextOfAnEarlierAttemptIsIgnored() {
        let parsed = MessageEnvelope.parse("]]>openui:content\na\n]]>openui:context\n[1]\n]]>openui:end\n]]>openui:content\nb")

        #expect(parsed.content == "b")
        #expect(parsed.context == nil)
        #expect(!parsed.isEnded)
    }
}

@Suite("Markdown parser")
struct MarkdownParserTests {
    @Test func parsesBlocks() {
        let blocks = MarkdownParser.parse("""
        # Title
        Intro **bold**
        continues here

        - one
        - two
          - nested
        - [x] done

        1. first
        2. second

        > quoted

        ```swift
        let x = 1
        ```

        | Day | Plan |
        |:----|-----:|
        | 1 | Alfama |

        ---
        """)
        guard blocks.count == 8 else {
            Issue.record("unexpected blocks: \(blocks)")
            return
        }
        #expect(blocks[0] == .heading(level: 1, text: "Title"))
        #expect(blocks[1] == .paragraph("Intro **bold**\ncontinues here"))
        if case .list(let list) = blocks[2] {
            #expect(!list.ordered)
            #expect(list.items.map(\.text) == ["one", "two", "done"])
            #expect(list.items[2].checked == true)
            if case .list(let nested)? = list.items[1].children.first {
                #expect(nested.items.map(\.text) == ["nested"])
            } else {
                Issue.record("missing nested list")
            }
        }
        if case .list(let ordered) = blocks[3] {
            #expect(ordered.ordered)
            #expect(ordered.items.count == 2)
        }
        #expect(blocks[4] == .quote([.paragraph("quoted")]))
        #expect(blocks[5] == .code(language: "swift", code: "let x = 1"))
        if case .table(let table) = blocks[6] {
            #expect(table.header == ["Day", "Plan"])
            #expect(table.alignments == [.leading, .trailing])
            #expect(table.rows == [["1", "Alfama"]])
        }
        #expect(blocks[7] == .rule)
    }

    @Test func toleratesStreamingInput() {
        #expect(MarkdownParser.parse("```py\nprint(1)") == [.code(language: "py", code: "print(1)")])
        #expect(MarkdownParser.parse("- a\n- ").count == 1)
    }
}

@Suite("Incremental editing")
struct StatementMergerTests {
    let original = """
    root = Stack([header, tbl])
    header = CardHeader("Tickets")
    tickets = Query("list_tickets", {}, {rows: []})
    tbl = Table([Col("Title", tickets.rows.title), Col("Status", tickets.rows.status)])
    """

    @Test func mergesPatchByStatementName() {
        let patch = """
        root = Stack([header, chart, tbl])
        chart = PieChart(["Open", "Closed"], [@Count(@Filter(tickets.rows, "status", "==", "open")), @Count(@Filter(tickets.rows, "status", "==", "closed"))], "donut")
        """
        let merged = StatementMerger.merge(original, patch: patch)
        let lines = merged.components(separatedBy: "\n")
        #expect(lines.count == 5)
        #expect(lines[0] == "root = Stack([header, chart, tbl])")
        #expect(lines[1] == "header = CardHeader(\"Tickets\")")
        #expect(lines[4].hasPrefix("chart = PieChart("))
    }

    @Test func deletesAndCollectsGarbage() {
        let merged = StatementMerger.merge(original + "\n$filter = \"open\"", patch: "```openui-lang\nroot = Stack([header])\n```")
        #expect(merged == "root = Stack([header])\nheader = CardHeader(\"Tickets\")\n$filter = \"open\"")
        let deleted = StatementMerger.merge("root = Stack([a, b])\na = 1\nb = 2", patch: "b = null")
        #expect(deleted == "root = Stack([a, b])\na = 1")
    }

    @Test func emptyInputs() {
        #expect(StatementMerger.merge("", patch: "root = Stack([])") == "root = Stack([])")
        #expect(StatementMerger.merge(original, patch: "   ") == original)
    }
}
