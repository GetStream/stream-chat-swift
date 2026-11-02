//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamChatAI

/// One reply's surfaces, which follow its messages as the agent writes them.
@MainActor
final class A2UIReply: ObservableObject {
    let processor: A2UIMessageProcessor
    @Published private(set) var surfaceIds: [String] = []
    private(set) var isStreaming = false
    private var applied: [String] = []
    private var messages: AnyCancellable?

    init(processor: A2UIMessageProcessor, onMessage: @escaping @MainActor (RendererMessage) -> Void) {
        self.processor = processor
        messages = processor.rendererMessages.sink { message in
            MainActor.assumeIsolated { onMessage(message) }
        }
    }

    /// Applies the messages of `source` not applied yet. Messages that changed, rather than
    /// grew, start the surfaces again.
    func update(source: String, isStreaming: Bool) {
        self.isStreaming = isStreaming
        let messages = A2UIStream.messages(in: source)
        if !messages.starts(with: applied) {
            processor.clearSurfaces(emitUpdates: false)
            applied = []
        }
        for raw in messages.dropFirst(applied.count) {
            guard var json = Json.decodeMap(raw) else {
                log.error("A reply's A2UI message isn't a JSON object")
                continue
            }
            // The fence names the version as 1.0, which a model may copy into the messages in
            // another spelling.
            if let version = json[A2UIProtocol.versionKey] as? String, Self.versionSpellings.contains(version) {
                json[A2UIProtocol.versionKey] = A2UIProtocol.version
            }
            processor.handle(json: json)
        }
        applied = messages
        if surfaceIds != processor.surfaceIds {
            surfaceIds = processor.surfaceIds
        }
    }

    private static let versionSpellings: Set<String> = ["1", "1.0.0", "v1"]
}
