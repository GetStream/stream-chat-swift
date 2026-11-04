//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatOpenUI
import Testing

/// Port of `lang-core/src/parser/__tests__/parser.test.ts`.
@Suite("Parser")
struct ParserTests {
    /// Stack(children), Title(text), Table(columns, rows).
    let schema = ParamMap([
        ("Stack", [ParamDef(name: "children", required: true)]),
        ("Title", [ParamDef(name: "text", required: true)]),
        ("Table", [ParamDef(name: "columns", required: true), ParamDef(name: "rows", required: true)])
    ])

    func parse(_ input: String) -> ParseResult {
        OpenUIParser(paramMap: schema).parse(input)
    }

    func codes(_ input: String) -> [String] {
        parse(input).meta.errors.map(\.code.rawValue)
    }

    func children(_ result: ParseResult) -> [OpenUIValue] {
        result.root?.props["children"]?.arrayValue ?? []
    }

    // MARK: unknown-component

    @Test func reportsUnknownComponent() {
        let result = parse(#"root = DataTable("col")"#)
        #expect(result.meta.errors.count == 1)
        #expect(result.meta.errors.first?.code == .unknownComponent)
        #expect(result.meta.errors.first?.component == "DataTable")
        #expect(result.root == nil)
    }

    @Test func reportsUnknownComponentsInTree() {
        #expect(codes("root = Stack([Ghost(\"a\")])\n").contains("unknown-component"))
    }

    @Test func doesNotReportKnownComponents() {
        let result = parse(#"root = Stack(["hello"])"#)
        #expect(result.meta.errors.isEmpty)
    }

    // MARK: excess-args

    @Test func reportsExcessArgsButStillRenders() {
        let result = parse(#"root = Title("hello", "extra")"#)
        #expect(codes(#"root = Title("hello", "extra")"#).contains("excess-args"))
        #expect(result.root?.props["text"] == "hello")
    }

    @Test func excessArgsMessageListsCount() {
        let error = parse(#"root = Title("hello", "extra", "more")"#).meta.errors.first { $0.code == .excessArgs }
        #expect(error?.message.contains("2 excess dropped") == true)
    }

    @Test func noExcessArgsWhenCountsMatch() {
        #expect(!codes(#"root = Title("hello")"#).contains("excess-args"))
        #expect(!codes("root = Table([], [])").contains("excess-args"))
    }

    // MARK: unresolved references

    @Test func tracksUnresolvedReferences() {
        let result = parse("root = Stack([tbl])")
        #expect(result.meta.unresolved.contains("tbl"))
        #expect(result.meta.errors.isEmpty)
    }

    @Test func clearsUnresolvedWhenDefined() {
        #expect(parse("root = Stack([tbl])\ntbl = Title(\"hello\")").meta.unresolved.isEmpty)
    }

    @Test func streamingTracksAndResolvesForwardReferences() {
        var parser = OpenUIStreamParser(paramMap: schema)
        let mid = parser.push("root = Stack([tbl])\n")
        #expect(mid.meta.unresolved.contains("tbl"))
        #expect(mid.meta.errors.isEmpty)
        let done = parser.push("tbl = Title(\"hello\")\n")
        #expect(done.meta.unresolved.isEmpty)
    }

    @Test func streamingKeepsUnresolvedAtEndOfStream() {
        var parser = OpenUIStreamParser(paramMap: schema)
        _ = parser.push("root = Stack([tbl])\n")
        let result = parser.result()
        #expect(result.meta.unresolved.contains("tbl"))
        #expect(result.meta.errors.isEmpty)
    }

    // MARK: required props

    @Test func missingRequiredShape() {
        let result = parse("root = Stack()")
        #expect(result.meta.errors.count == 1)
        #expect(result.meta.errors.first?.code == .missingRequired)
        #expect(result.meta.errors.first?.component == "Stack")
    }

    @Test func nullRequiredShape() {
        let result = parse("root = Stack(null)")
        #expect(result.meta.errors.count == 1)
        #expect(result.meta.errors.first?.code == .nullRequired)
    }

    // MARK: array null-dropping

    @Test func dropsUnresolvedRefsFromArrays() {
        let items = children(parse("root = Stack([missing, t1])\nt1 = Title(\"ok\")"))
        #expect(items.count == 1)
        #expect(items.first?.elementValue?.typeName == "Title")
    }

    @Test func dropsInvalidComponentsFromArrays() {
        let items = children(parse("root = Stack([bad, good])\nbad = Title()\ngood = Title(\"ok\")"))
        #expect(items.count == 1)
        #expect(items.first?.elementValue?.props["text"] == "ok")
    }

    @Test func dropsUnknownComponentsFromArrays() {
        let items = children(parse("root = Stack([u, t1])\nu = Ghost(\"x\")\nt1 = Title(\"ok\")"))
        #expect(items.count == 1)
        #expect(items.first?.elementValue?.typeName == "Title")
    }

    @Test func preservesNullLiteralsInArrays() {
        #expect(children(parse("root = Stack([null, null])")) == [.null, .null])
    }

    @Test func streamingFillsInLaterDefinitions() {
        var parser = OpenUIStreamParser(paramMap: schema)
        let first = parser.push("root = Stack([t1, t2])\nt1 = Title(\"first\")\n")
        #expect(children(first).count == 1)
        let second = parser.push("t2 = Title(\"second\")\n")
        #expect(children(second).count == 2)
    }

    // MARK: orphaned statements

    @Test func detectsOrphanedStatements() {
        let result = parse("root = Stack([t1])\nt1 = Title(\"used\")\norphan = Title(\"unused\")")
        #expect(result.meta.orphaned == ["orphan"])
    }

    @Test func noOrphansWhenAllReachable() {
        #expect(parse("root = Stack([t1, t2])\nt1 = Title(\"a\")\nt2 = Title(\"b\")").meta.orphaned.isEmpty)
    }

    @Test func orphanedDuringStreaming() {
        var parser = OpenUIStreamParser(paramMap: schema)
        let result = parser.push("root = Stack([t1])\nt1 = Title(\"a\")\norphan = Title(\"stray\")\n")
        #expect(result.meta.orphaned == ["orphan"])
    }

    @Test func detectsMultipleOrphans() {
        let result = parse("root = Stack([t1])\nt1 = Title(\"used\")\na = Title(\"x\")\nb = Title(\"y\")")
        #expect(result.meta.orphaned == ["a", "b"])
    }

    @Test func deeplyNestedRefsAreNotOrphaned() {
        let result = parse("root = Stack([t1])\nt1 = Table([col], rows)\ncol = Title(\"Name\")\nrows = [[\"Alice\"]]")
        #expect(result.meta.orphaned.isEmpty)
    }

    // MARK: fences and comments inside strings

    @Test func preservesFencesInsideStrings() {
        let result = parse(#"root = Title("```js\nconsole.log(\"Hello World\");\n```")"#)
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["text"] == .string("```js\nconsole.log(\"Hello World\");\n```"))
    }

    @Test func preservesPythonFenceInsideStrings() {
        let result = parse(#"root = Title("```python\nprint('hi')\n```")"#)
        #expect(result.root?.props["text"] == .string("```python\nprint('hi')\n```"))
    }

    @Test func preservesSlashesInsideMultilineStrings() {
        let result = parse("root = Title(\"\nHello // World\nhttps://example.com/\n\")")
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["text"] == .string("\nHello // World\nhttps://example.com/\n"))
    }

    @Test func preservesHashInsideMultilineStrings() {
        let result = parse("root = Title(\"\nHello # World\nhttps://example.com/\n\")")
        #expect(result.root?.props["text"] == .string("\nHello # World\nhttps://example.com/\n"))
    }

    @Test func apostrophesOutsideFencesDoNotOpenStrings() {
        let code = "Here's the code:\n\n```js\nroot = Title(\"hello\")\n```"
        let result = parse(code)
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["text"] == "hello")
    }

    // MARK: redefined statement IDs

    let withNewline = "root = Stack([a])\na = Title(\"x\")\na = Title(\"y\")\n"
    let withoutNewline = "root = Stack([a])\na = Title(\"x\")\na = Title(\"y\")"

    func titleText(_ result: ParseResult) -> String? {
        children(result).first?.elementValue?.props["text"]?.stringValue
    }

    @Test func parseIsLastWins() {
        #expect(titleText(parse(withNewline)) == "y")
        #expect(titleText(parse(withoutNewline)) == "y")
    }

    @Test func streamLastWinsForSinglePush() {
        for text in [withNewline, withoutNewline] {
            var parser = OpenUIStreamParser(paramMap: schema)
            _ = parser.push(text)
            #expect(titleText(parser.result()) == "y")
        }
    }

    @Test func streamLastWinsLineByLineAndCharByChar() {
        var lines: [String] = []
        var current = ""
        for character in withNewline {
            current.append(character)
            if character == "\n" {
                lines.append(current)
                current = ""
            }
        }
        if !current.isEmpty { lines.append(current) }

        var lineParser = OpenUIStreamParser(paramMap: schema)
        for line in lines {
            _ = lineParser.push(line)
        }
        #expect(titleText(lineParser.result()) == "y")

        for text in [withNewline, withoutNewline] {
            var charParser = OpenUIStreamParser(paramMap: schema)
            for character in text {
                _ = charParser.push(String(character))
            }
            #expect(titleText(charParser.result()) == "y")
        }
    }

    @Test func streamLastWinsAcrossTwoChunks() {
        var parser = OpenUIStreamParser(paramMap: schema)
        _ = parser.push("root = Stack([a])\na = Title(\"x\")\n")
        _ = parser.push("a = Title(\"y\")\n")
        #expect(titleText(parser.result()) == "y")

        var parser2 = OpenUIStreamParser(paramMap: schema)
        _ = parser2.push("root = Stack([a])\na = Title(\"x\")\n")
        _ = parser2.push("a = Title(\"y\")")
        #expect(titleText(parser2.result()) == "y")
    }

    @Test func streamLastWinsViaSet() {
        var parser = OpenUIStreamParser(paramMap: schema)
        #expect(titleText(parser.set(withoutNewline)) == "y")
    }

    @Test func incompleteRedefinitionDoesNotClobberCompletedStatement() {
        var parser = OpenUIStreamParser(paramMap: schema)
        _ = parser.push("root = Stack([a])\na = Title(\"x\")\n")
        #expect(titleText(parser.push("a = Title(\"y")) == "x")
        #expect(titleText(parser.push("\")\n")) == "y")
    }
}
