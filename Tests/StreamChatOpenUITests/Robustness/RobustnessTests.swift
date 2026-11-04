//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
@Suite("Robustness against model output")
struct RobustnessTests {
    @Test func deeplyNestedArraysDoNotOverflowTheStack() {
        let depth = 20000
        let program = "root = Stack([" + String(repeating: "[", count: depth) + #"TextContent("x")"# + String(repeating: "]", count: depth) + "])"

        let result = ComponentLibrary.openUI.parser.parse(program)

        #expect(result.root?.typeName == "Stack")
    }

    @Test func longReferenceChainsDoNotOverflowTheStack() {
        let count = 5000
        var lines = ["root = Stack([a0])"]
        for index in 0..<count {
            lines.append("a\(index) = Stack([a\(index + 1)])")
        }
        lines.append(#"a\#(count) = TextContent("x")"#)

        let runtime = OpenUIRuntime(library: .openUI)
        runtime.update(response: lines.joined(separator: "\n"), isStreaming: false)

        #expect(runtime.root?.typeName == "Stack")
    }

    @Test func longOperatorChainsDoNotOverflowTheStack() {
        let terms = 20000
        let nested = (0..<200).reduce("1") { inner, _ in "(" + inner + String(repeating: " + 1", count: 200) + ")" }
        let chains = [
            Array(repeating: "1", count: terms).joined(separator: " + "),
            "a" + String(repeating: ".b", count: terms),
            "a" + String(repeating: "[0]", count: terms),
            nested
        ]

        for chain in chains {
            let result = ComponentLibrary.openUI.parser.parse("root = Stack([TextContent(\"x\")])\nv = \(chain)")

            #expect(result.root?.typeName == "Stack")
            #expect(treeHeight(ExpressionParser.parse(Lexer.tokenize(chain))) <= 2 * ExpressionParser.maxDepth)
        }
    }

    @Test func shortOperatorChainsAreKept() {
        let chain = Array(repeating: "1", count: 200).joined(separator: " + ")
        let runtime = OpenUIRuntime(library: .openUI)
        runtime.update(response: "root = Stack([TextContent(\"\" + (\(chain)))])", isStreaming: false)

        #expect(runtime.root?.props["children"]?.arrayValue?.first?.elementValue?.props["text"] == "200")
    }

    @Test func nestingWithinTheLimitsIsKept() {
        let program = "root = Stack([" + String(repeating: "Stack([", count: 50) + #"TextContent("deep")"# + String(repeating: "])", count: 50) + "])"

        let result = ComponentLibrary.openUI.parser.parse(program)

        #expect(OpenUIJSON.stringify(.element(result.root!)).contains("deep"))
        #expect(result.meta.errors.isEmpty)
    }

    @Test func windowsLineEndingsWithCommentsKeepEveryStatement() {
        let program = "root = Stack([a, b]) // page\r\na = TextContent(\"A\")\r\n# note\r\nb = TextContent(\"B\")"

        let result = ComponentLibrary.openUI.parser.parse(program)

        #expect(result.root?.props["children"]?.arrayValue?.count == 2)
        #expect(result.meta.unresolved.isEmpty)
    }

    @Test func stripCommentsSplitsOnLineFeedsLikeJavaScript() {
        #expect(Preprocessor.stripComments("a = 1 // x\r\nb = 2") == "a = 1\nb = 2")
    }

    @Test func messageEnvelopeReadsWindowsLineEndings() {
        let message = "]]>openui:content\r\nroot = Stack([])\r\n]]>openui:context\r\n[1]"

        let parsed = MessageEnvelope.parse(message)

        #expect(parsed.content == "root = Stack([])")
        #expect(parsed.context == [1])
    }

    @Test func messageEnvelopeKeepsTheLastCharacterBeforeAWindowsSeparator() {
        let parsed = MessageEnvelope.parse("root = Stack([])\r\n]]>openui:context\r\n[]")

        #expect(parsed.content == "root = Stack([])")
    }

    @Test func refreshIntervalsWaitAtLeastTheToolProvidersMinimumAndAreClampedLikeSetInterval() {
        #expect(QueryManager.refreshNanoseconds(30, minimum: 5) == 30_000_000_000)
        #expect(QueryManager.refreshNanoseconds(0.001, minimum: 5) == 5_000_000_000)
        #expect(QueryManager.refreshNanoseconds(.nan, minimum: 5) == 5_000_000_000)
        #expect(QueryManager.refreshNanoseconds(.infinity, minimum: 5) == 2_147_483_647_000_000)
        #expect(QueryManager.refreshNanoseconds(1e300, minimum: 5) == 2_147_483_647_000_000)
        #expect(QueryManager.refreshNanoseconds(1e-12, minimum: 0) == 1_000_000)
        #expect(QueryManager.refreshNanoseconds(1e-12, minimum: .nan) == 1_000_000)
    }

    @Test func toolProvidersRefreshEveryFiveSecondsAtMostByDefault() {
        #expect(FunctionToolProvider([:]).minimumRefreshInterval == 5)
        #expect(FunctionToolProvider([:], minimumRefreshInterval: 1).minimumRefreshInterval == 1)
        #expect(HostToolProvider(host: nil).minimumRefreshInterval == 5)
    }

    @Test func queryWithAnInfiniteRefreshIntervalDoesNotCrash() async throws {
        let tools = FunctionToolProvider(["list": { _ in ["rows": []] }])
        let runtime = OpenUIRuntime(library: .openUI, toolProvider: tools)
        runtime.update(response: "root = Stack([])\nq = Query(\"list\", {}, {rows: []}, 1e999)", isStreaming: false)

        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(runtime.root != nil)
    }

    @Test func nonFiniteNumbersRenderWithoutTrapping() {
        let program = """
        root = Stack([notes, slider, pie, radial])
        notes = TextArea("notes", "Notes", 1e19)
        slider = Slider("price", "continuous", 0, @Round(1, 400))
        pie = PieChart(["A", "B"], [1e999, 1])
        radial = RadialChart(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], [1, 2, 3, 4, 5, 6, 7])
        """
        let runtime = OpenUIRuntime(library: .openUI)
        runtime.update(response: program, isStreaming: false)

        #expect(RenderingTests.render(runtime) != nil)
    }

    @Test func legendPercentIsNilWhenTheNumbersDoNotMakeOne() {
        #expect(LegendView.percent(1, of: 4) == 25)
        #expect(LegendView.percent(.infinity, of: .infinity) == nil)
        #expect(LegendView.percent(.nan, of: 1) == nil)
        #expect(LegendView.percent(1e20, of: 1) == nil, "finite, but too large for an Int")
    }

    @Test func sliderStepsAreOnesSwiftUITakes() {
        let bounds = SliderValues.bounds(minimum: 0, maximum: 100)

        #expect(SliderValues.step(101, discrete: false, in: bounds) == nil)
        #expect(SliderValues.step(.infinity, discrete: false, in: bounds) == nil)
        #expect(SliderValues.step(5, discrete: false, in: bounds) == 5)
        #expect(SliderValues.step(nil, discrete: true, in: bounds) == 1)
        #expect(SliderValues.step(nil, discrete: true, in: 0...0.5) == nil)
        #expect(SliderValues.bounds(minimum: 1e16, maximum: 0) == 1e15...(1e15 + 1))
    }

    @Test func sliderStepsTooSmallForTheRangeAreLeftToSnapping() {
        let bounds = SliderValues.bounds(minimum: 0, maximum: 100)

        #expect(SliderValues.step(nil, discrete: true, in: SliderValues.bounds(minimum: 0, maximum: 1e15)) == nil)
        #expect(SliderValues.step(1e-8, discrete: false, in: bounds) == nil)
        #expect(SliderValues.requestedStep(1e-8, discrete: false, in: bounds) == 1e-8)
        #expect(SliderValues.step(0.5, discrete: false, in: bounds) == 0.5)
        #expect(SliderValues.step(nil, discrete: true, in: 0...1000) == 1)
        #expect(SliderValues.step(nil, discrete: true, in: 0...5000) == nil)
        #expect(SliderValues.requestedStep(nil, discrete: true, in: 0...5000) == 1)
        #expect(SliderValues.snapped(2345.678, to: 1, in: 0...5000) == 2346)
        #expect(SliderValues.snapped(4999.9, to: 7, in: 0...5000) == 4998)
        #expect(SliderValues.snapped(-3, to: 7, in: 0...5000) == 0)
    }

    @Test func aGridGapThatIsNegativeOrNotFiniteIsNoGap() {
        #expect(ResponsiveGridLayout(spacing: -150).spacing == 0)
        #expect(ResponsiveGridLayout(spacing: .infinity).spacing == 0)
        #expect(ResponsiveGridLayout(spacing: 8).spacing == 8)
        #expect(ResponsiveGridLayout(minItemWidth: -1).minItemWidth == 1)
    }

    @Test func aGridWithANegativeGapLaysOut() {
        let items = (0..<4).map { #"SnippetCardItem("i\#($0)", IconText(Icon("star"), "neutral", "m", "A"))"# }.joined(separator: ", ")
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: #"root = Card([SnippetCardBlock([\#(items)], "grid", true, null, -150)])"#, isStreaming: false)

        #expect(RenderingTests.render(runtime) != nil)
    }

    @Test func deeplyNestedQuotesInTextDoNotOverflowTheStack() {
        let blocks = MarkdownParser.parse(String(repeating: ">", count: 10000) + " hello")

        var depth = 0
        var current = blocks
        while case .quote(let inner)? = current.first {
            depth += 1
            current = inner
        }
        #expect(depth == MarkdownParser.maxDepth)
        #expect(!current.isEmpty, "what is deeper reads as text")
    }

    @Test func tabIndentedTextUnderAListItemDoesNotLoopForever() {
        let compare = MarkdownList.Item(text: "Compare", checked: nil, children: [.paragraph("x >= y")])

        #expect(MarkdownParser.parse("1. Compare\n\tx >= y") == [.list(MarkdownList(ordered: true, start: 1, items: [compare]))])
    }

    @Test func tabIndentedBlocksUnderAListItemKeepTheirMarkers() {
        let blocks = MarkdownParser.parse("- a\n\t> quoted\n\t- b")

        let item = MarkdownList.Item(text: "a", checked: nil, children: [
            .quote([.paragraph("quoted")]),
            .list(MarkdownList(ordered: false, start: 0, items: [MarkdownList.Item(text: "b", checked: nil, children: [])]))
        ])
        #expect(blocks == [.list(MarkdownList(ordered: false, start: 0, items: [item]))])
    }

    @Test func referencesThatDoubleOnEachLevelStopExpanding() {
        var lines = [#"a0 = TextContent("x")"#]
        for level in 1...22 {
            lines.append("a\(level) = [a\(level - 1), a\(level - 1)]")
        }
        lines.append("root = Card([a22])")
        let started = ProcessInfo.processInfo.systemUptime

        let result = ComponentLibrary.openUIChat.parser.parse(lines.joined(separator: "\n"))

        #expect(result.root?.typeName == "Card")
        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
    }

    @Test func referencesUsedManyTimesStopMaterializingAtTheNodeBudget() {
        let row = Array(repeating: "{a: 1}", count: 1000).joined(separator: ", ")
        let rows = Array(repeating: "c", count: 5000).joined(separator: ", ")
        let program = "root = Stack([])\nc = [\(row)]\nb = [\(rows)]\n$data = b"

        let result = ComponentLibrary.openUI.parser.parse(program)

        let materialized = valueCount(result.stateDeclarations["$data"] ?? .null)
        #expect(materialized > 10000)
        #expect(materialized <= Materializer.maxNodes)
    }

    @Test func nestedEachLoopsStopAtTheEvaluationBudget() {
        let items = "[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]"
        let template = (0..<6).reduce(#"TextContent("x")"#) { inner, level in #"@Each(\#(items), "v\#(level)", \#(inner))"# }
        let runtime = OpenUIRuntime(library: .openUI)

        runtime.update(response: "root = Stack([\(template)])", isStreaming: false)

        let elements = elementCount(runtime.root.map(OpenUIValue.element) ?? .null)
        #expect(elements > 1000)
        #expect(elements < EvaluationBudget.maxNodes)
        #expect(runtime.errors.filter { $0.message.contains("Evaluation stopped") }.count == 1)
    }

    @Test func eachLoopsWithinTheBudgetAreKept() {
        let items = "[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]"
        let runtime = OpenUIRuntime(library: .openUI)

        runtime.update(response: #"root = Stack([@Each(\#(items), "a", @Each(\#(items), "b", TextContent("x")))])"#, isStreaming: false)

        #expect(elementCount(runtime.root.map(OpenUIValue.element) ?? .null) == 101)
        #expect(runtime.errors.isEmpty)
    }

    @Test func aPatternThatBacktracksGivesUpInsteadOfFreezing() throws {
        let expression = try NSRegularExpression(pattern: "^(a+)+$")
        let started = ProcessInfo.processInfo.systemUptime

        #expect(FormValidation.firstMatch(of: expression, in: String(repeating: "a", count: 28) + "!") == nil)
        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(FormValidation.firstMatch(of: expression, in: "aaa") == true)
    }

    @Test func imagesLoadOnlyFromLinksTheModelWroteOrAToolReturned() async {
        let tools = FunctionToolProvider(["photos": { _ in ["url": "https://cdn.example/tool.png"] }])
        let runtime = OpenUIRuntime(library: .openUIChat, toolProvider: tools)
        runtime.update(response: """
        root = Card([TextContent(photos.url), TextContent(logo)])
        photos = Query("photos", {}, {url: ""})
        logo = "https://cdn.example/logo.png"
        """, isStreaming: false)

        #expect(runtime.allowsImageLink("https://cdn.example/logo.png"))
        #expect(await waitUntil { runtime.allowsImageLink("https://cdn.example/tool.png") })
        #expect(!runtime.allowsImageLink("https://attacker.example/p?pw=hunter22"))
        #expect(!runtime.allowsImageLink("https://cdn.example/logo.png?q=h"), "a written link with typed text after it")
        #expect(!runtime.allowsImageLink(""))
    }

    @Test func passwordsNeverLeaveTheDevice() {
        let form: OpenUIObject = [
            "login": ["pw": ["value": "hunter22", "componentType": "Input", "secret": true], "email": ["value": "a@b.co", "componentType": "Input"]]
        ]
        let event = ActionEvent(type: "continue_conversation", humanFriendlyMessage: "Sign in", formState: form, formName: "login")

        #expect(form.withoutSecrets == ["login": ["email": ["value": "a@b.co", "componentType": "Input"]]])
        #expect(!event.assistantMessage.contains("hunter22"))
        #expect(event.assistantMessage.contains("a@b.co"))
    }

    @Test func textAreaLineCountIsKeptInRange() {
        #expect(TextInputView.lineCount(rows: nil) == 3)
        #expect(TextInputView.lineCount(rows: 5) == 5)
        #expect(TextInputView.lineCount(rows: 0) == 2)
        #expect(TextInputView.lineCount(rows: 1e19) == 100)
        #expect(TextInputView.lineCount(rows: .infinity) == 3)
        #expect(TextInputView.lineCount(rows: .nan) == 3)
    }

    @Test func onlyWebAndEmailLinksStayTappable() {
        let text = "[web](https://getstream.io) [call](tel:+15550100) [app](otherapp://pay?to=x) [mail](mailto:a@b.co)"

        let links = InlineMarkdown.attributed(text).runs.compactMap(\.link).map(\.absoluteString)

        #expect(links == ["https://getstream.io", "mailto:a@b.co"])
        #expect(String(InlineMarkdown.attributed(text).characters) == "web call app mail")
    }
}

private func treeHeight(_ node: ASTNode) -> Int {
    let children: [ASTNode]
    switch node {
    case .comp(_, let args, let mappedProps, _): children = args + (mappedProps ?? []).map(\.value)
    case .arr(let elements): children = elements
    case .obj(let entries): children = entries.map(\.value)
    case .binary(_, let left, let right): children = [left, right]
    case .unary(_, let operand): children = [operand]
    case .ternary(let condition, let then, let otherwise): children = [condition, then, otherwise]
    case .member(let object, _): children = [object]
    case .index(let object, let index): children = [object, index]
    case .assign(_, let value): children = [value]
    case .str, .num, .bool, .null, .ref, .placeholder, .stateRef, .runtimeRef: children = []
    }
    var height = 0
    for child in children {
        height = max(height, treeHeight(child))
    }
    return 1 + height
}

private func elementCount(_ value: OpenUIValue) -> Int {
    switch value {
    case .element(let element):
        var count = 1
        for child in element.props.values {
            count += elementCount(child)
        }
        return count
    case .array(let items):
        var count = 0
        for item in items {
            count += elementCount(item)
        }
        return count
    case .object, .null, .bool, .number, .string, .expression:
        return 0
    }
}

private func valueCount(_ value: OpenUIValue) -> Int {
    switch value {
    case .array(let items):
        var count = 1
        for item in items {
            count += valueCount(item)
        }
        return count
    case .object(let object):
        var count = 1
        for item in object.values {
            count += valueCount(item)
        }
        return count
    case .element(let element):
        var count = 1
        for item in element.props.values {
            count += valueCount(item)
        }
        return count
    case .null, .bool, .number, .string, .expression:
        return 1
    }
}
