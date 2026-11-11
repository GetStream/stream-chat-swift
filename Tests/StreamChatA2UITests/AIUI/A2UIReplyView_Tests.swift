//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamChatA2UI
import StreamChatAI
import SwiftUI
import UIKit
import XCTest

@MainActor
final class A2UIReplyView_Tests: XCTestCase {
    private let createSurface = #"{"version": "1.0", "createSurface": {"surfaceId": "plan", "catalogId": "getstream.io:app-catalog"}}"#
    private let components = #"{"version": "1.0", "updateComponents": {"surfaceId": "plan", "components": [{"id": "root", "component": "Column", "children": ["title"]}, {"id": "title", "component": "Text", "text": "Ohrid"}]}}"#

    final class Feed: ObservableObject {
        @Published var document: AIUIDocument

        init(document: AIUIDocument) {
            self.document = document
        }
    }

    // Shows a reply the way a conversation does: the engine makes its view each time the
    // reply's document changes.
    struct Screen: View {
        @ObservedObject var feed: Feed
        let engine: A2UIEngine

        var body: some View {
            engine.view(for: feed.document, messageID: "m1")
        }
    }

    func test_aLastWriteThatCompletesAMessageAndTheDocument_keepsTheMessage() async throws {
        // While the agent writes: the surface is made, and its components are on their way.
        let feed = Feed(document: document([createSurface, String(components.dropLast(2))], isStreaming: true))
        let host = AIUIHost { A2UIRenderer() } send: { _ in }
        let engine = A2UIEngine(renderer: A2UIRenderer(), host: host)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIHostingController(rootView: Screen(feed: feed, engine: engine))
        window.makeKeyAndVisible()
        try await settle(window)
        let reply = try XCTUnwrap(engine.replies["m1"])
        XCTAssertEqual(reply.surfaceIds, ["plan"])
        XCTAssertNil(reply.processor.surfaceViewModel("plan").definition?.root)

        // The agent's last write closes the components and marks the document complete, in
        // one change.
        feed.document = document([createSurface, components], isStreaming: false)
        try await settle(window)

        XCTAssertFalse(reply.isStreaming)
        XCTAssertNotNil(reply.processor.surfaceViewModel("plan").definition?.component("title"))
        window.isHidden = true
    }

    private func document(_ messages: [String], isStreaming: Bool) -> AIUIDocument {
        AIUIDocument(format: .a2ui, version: "1.0", isStreaming: isStreaming, content: .string(messages.joined(separator: "\n")))
    }

    private func settle(_ window: UIWindow) async throws {
        for _ in 0..<3 {
            try await Task.sleep(nanoseconds: 100_000_000)
            window.layoutIfNeeded()
        }
    }
}
