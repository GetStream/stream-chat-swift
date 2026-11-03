//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
@Suite("OpenUIView")
struct OpenUIViewTests {
    static let program = #"root = Card([TextContent("Hello"), Buttons([Button("Go")])])"#

    @Test func ownedRuntimeShowsTheResponseInTheFirstFrame() throws {
        let image = try #require(RenderingTests.render(OpenUIView(response: Self.program, library: .openUIChat)))

        #expect(image.height > 40)
    }

    @Test func ownedRuntimeIsKeptAndFollowsTheLatestActionHandler() async {
        let owned = OwnedRuntime()
        var received: [String] = []
        let first = owned.runtime(library: .openUIChat, toolProvider: nil, initialState: nil, onAction: { _ in received.append("first") }, response: Self.program, isStreaming: false)
        let second = owned.runtime(library: .openUIChat, toolProvider: nil, initialState: nil, onAction: { _ in received.append("second") }, response: Self.program, isStreaming: false)

        #expect(first === second)
        #expect(first.root != nil)
        await second.triggerAction(label: "Go")
        #expect(received == ["second"])
    }

    @Test func ownedRuntimeIsKeptAndRendersWithTheLatestLibrary() throws {
        let owned = OwnedRuntime()
        let replaced = RenderCount()
        let first = owned.runtime(library: .openUIChat, toolProvider: nil, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        let library = ComponentLibrary.openUIChat.replacingRenderer(for: "TextContent") { _ in
            replaced.count += 1
            return AnyView(Text("Replaced"))
        }
        let second = owned.runtime(library: library, toolProvider: nil, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        _ = try #require(RenderingTests.render(second))

        #expect(first === second)
        #expect(replaced.count > 0)
    }

    @Test func aReplacedViewCanWrapTheLibrarysOwn() throws {
        let replaced = RenderCount()
        let original = RenderCount()
        let base = ComponentLibrary.openUIChat.replacingRenderer(for: "TextContent") { _ in
            original.count += 1
            return AnyView(Text("Original"))
        }
        let library = base.replacingView(of: .textContent) { context in
            replaced.count += 1
            return context.defaultView.padding()
        }
        let runtime = OwnedRuntime().runtime(library: library, toolProvider: nil, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        _ = try #require(RenderingTests.render(runtime))

        #expect(replaced.count > 0)
        #expect(original.count > 0, "the default view is the library's own")
        #expect(library.component(named: "TextContent")?.schema == ComponentLibrary.openUIChat.component(named: "TextContent")?.schema)
        #expect(library.replacingView(of: "Missing") { _ in Text("x") }.componentNames == library.componentNames)
    }

    @Test func ownedRuntimeIsRemadeForAnotherLibrary() {
        let owned = OwnedRuntime()
        let chat = owned.runtime(library: .openUIChat, toolProvider: nil, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        let standard = owned.runtime(library: .openUI, toolProvider: nil, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)

        #expect(chat !== standard)
        #expect(standard.library.root == "Stack")
    }

    @Test func ownedRuntimeCallsTheLatestToolProvider() async throws {
        let owned = OwnedRuntime()
        let first = FunctionToolProvider(["weather": { _ in "first" }])
        let second = FunctionToolProvider(["weather": { _ in "second" }])
        let runtime = owned.runtime(library: .openUIChat, toolProvider: first, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        let same = owned.runtime(library: .openUIChat, toolProvider: second, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        let tools = try #require(runtime.queryManager.toolProvider)

        #expect(runtime === same)
        #expect(try await tools.callTool("weather", arguments: [:]) == "second")
    }

    @Test func ownedRuntimeIsRemadeWhenToolsAreAdded() {
        let owned = OwnedRuntime()
        let withoutTools = owned.runtime(library: .openUIChat, toolProvider: nil, initialState: nil, onAction: nil, response: Self.program, isStreaming: false)
        let withTools = owned.runtime(library: .openUIChat, toolProvider: FunctionToolProvider([:]), initialState: nil, onAction: nil, response: Self.program, isStreaming: false)

        #expect(withoutTools !== withTools)
        #expect(withoutTools.queryManager.toolProvider == nil)
        #expect(withTools.queryManager.toolProvider != nil)
    }
}

@MainActor
final class RenderCount {
    var count = 0
}
