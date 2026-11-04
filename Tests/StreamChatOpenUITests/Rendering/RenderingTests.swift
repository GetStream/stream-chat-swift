//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
@Suite("Rendering")
struct RenderingTests {
    nonisolated static let programs = ParserConformanceTests.cases.filter { $0.library != "mini" }

    static func library(_ name: String) -> ComponentLibrary {
        name == "chat" ? .openUIChat : .openUI
    }

    // The reference renders a root, or the component a ternary entry (`rootExpression`) picks.
    static func rendersRoot(_ program: ParserConformanceTests.Case) -> Bool {
        !(program.result["root"]?.isNull ?? true) || program.result["rootExpression"] != nil
    }

    @discardableResult
    static func render(_ runtime: OpenUIRuntime, colorScheme: ColorScheme = .light) -> CGImage? {
        render(OpenUIView(runtime: runtime), colorScheme: colorScheme)
    }

    @discardableResult
    static func render(_ view: some View, colorScheme: ColorScheme = .light) -> CGImage? {
        let renderer = ImageRenderer(
            content: view
                .frame(width: 390)
                .environment(\.colorScheme, colorScheme)
        )
        renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
        return renderer.cgImage
    }

    @Test(arguments: programs)
    func rendersCompleteProgram(_ program: ParserConformanceTests.Case) {
        let runtime = OpenUIRuntime(library: Self.library(program.library))
        runtime.update(response: program.input, isStreaming: false)

        #expect((runtime.root != nil) == Self.rendersRoot(program), "\(program.name)")
        Self.render(runtime)
        Self.render(runtime, colorScheme: .dark)
    }

    @Test(arguments: programs)
    func rendersWhileStreaming(_ program: ParserConformanceTests.Case) {
        let runtime = OpenUIRuntime(library: Self.library(program.library))
        let checkpoints = Set(program.checkpoints)
        var text = ""
        for (step, chunk) in program.chunks.enumerated() {
            text += chunk
            runtime.update(response: text, isStreaming: true)
            if checkpoints.contains(step) {
                Self.render(runtime)
            }
        }
        runtime.update(response: text, isStreaming: false)

        #expect(runtime.response == program.input)
        #expect((runtime.root != nil) == Self.rendersRoot(program), "\(program.name)")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func markdownRendersEveryBlock(_ colorScheme: ColorScheme) {
        let markdown = """
        # Trip
        ## Day 1
        ### Morning
        A **bold** start with `code` and a [link](https://getstream.io).

        - Lake walk
          - Old town
        1. Breakfast
        2. Museum
        - [x] Book hotel
        - [ ] Pack

        > Quote with *emphasis*

        ```swift
        let trip = "Ohrid"
        ```

        | Place | Hours | Price |
        | :--- | :---: | ---: |
        | Museum | 9-17 | 5 |
        | Church | 8-20 | 0 |

        ---
        Plain closing line.
        """

        #expect(Self.render(MarkdownView(markdown, foreground: .primary), colorScheme: colorScheme) != nil)
    }

    @Test func ownedRuntimeViewRenders() {
        let view = OpenUIView(response: #"root = Card([TextContent("Hello")])"#, library: .openUIChat)

        #expect(Self.render(view) != nil)
    }
}
