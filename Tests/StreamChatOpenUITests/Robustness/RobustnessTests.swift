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
        #expect(parsed.context == "[1]")
    }

    @Test func messageEnvelopeKeepsTheLastCharacterBeforeAWindowsSeparator() {
        let parsed = MessageEnvelope.parse("root = Stack([])\r\n]]>openui:context\r\n[]")

        #expect(parsed.content == "root = Stack([])")
    }

    @Test func refreshIntervalsAreClampedLikeSetInterval() {
        #expect(QueryManager.refreshNanoseconds(5) == 5_000_000_000)
        #expect(QueryManager.refreshNanoseconds(.infinity) == 2_147_483_647_000_000)
        #expect(QueryManager.refreshNanoseconds(1e300) == 2_147_483_647_000_000)
        #expect(QueryManager.refreshNanoseconds(1e-12) == 1_000_000)
        #expect(QueryManager.refreshNanoseconds(.nan) == 1_000_000)
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
