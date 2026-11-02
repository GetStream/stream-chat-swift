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
