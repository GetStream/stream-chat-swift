//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// One reply's surfaces, which follow its messages as the agent writes them.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class A2UIReply: ObservableObject {
    let processor: A2UIMessageProcessor
    @Published private(set) var surfaceIds: [String] = []
    @Published private(set) var isStreaming = false
    private var applied: [String] = []
    private var scanner = A2UIStreamScanner()
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
        if self.isStreaming != isStreaming {
            self.isStreaming = isStreaming
            // The app's components read it while their surface renders, which nothing else
            // changes when only the reply's status does.
            for surfaceId in processor.surfaceIds {
                processor.surfaceViewModel(surfaceId).touch()
            }
        }
        // Only text that doesn't carry on from the last can change messages already applied.
        if !scanner.scan(source), !scanner.messages.starts(with: applied) {
            processor.clearSurfaces(emitUpdates: false)
            applied = []
        }
        let messages = scanner.messages
        for (offset, raw) in messages.enumerated().dropFirst(applied.count) {
            // The message's text can hold what the person wrote, so the error leaves it out.
            guard var json = Json.decodeMap(raw) else {
                processor.report(RendererError(
                    code: RendererError.Code.validationFailed,
                    message: "Message \(offset + 1) of the reply couldn't be read as a JSON object."
                ))
                continue
            }
            if let version = json[A2UIProtocol.versionKey] as? String, Self.versionSpellings.contains(version) {
                json[A2UIProtocol.versionKey] = A2UIProtocol.version
            }
            processor.handle(json: json)
        }
        applied = messages
        if !isStreaming, scanner.hasOpenMessage {
            processor.report(RendererError(
                code: RendererError.Code.validationFailed,
                message: "The reply ends in the middle of a message, which is left out."
            ))
        }
        if surfaceIds != processor.surfaceIds {
            surfaceIds = processor.surfaceIds
        }
    }

    /// Other spellings of version 1.0, which the fence names and a model may copy into the
    /// messages, or which agents prompted before the 1.0 release write.
    static let versionSpellings: Set<String> = ["1", "1.0.0", "v1", "v1.0"]
}
