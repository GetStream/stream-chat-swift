//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's on-device model (Foundation Models), on iOS 26 and later with Apple Intelligence
/// turned on. It answers without a network connection, and the conversation never leaves the
/// device.
///
/// It is a small model, good for short answers and for working with what is in the
/// conversation. Its context holds a few thousand tokens, so the oldest turns of a long
/// conversation are left out.
public struct AIOnDeviceModel: AILocalModel {
    /// The longest answer, in tokens.
    public var maximumResponseTokens: Int

    public init(maximumResponseTokens: Int = 1000) {
        self.maximumResponseTokens = maximumResponseTokens
    }

    public var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    public func reply(instructions: String, turns: [AIConversationTurn]) -> AsyncThrowingStream<String, Error> {
        let maximumResponseTokens = maximumResponseTokens
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    #if canImport(FoundationModels)
                    if #available(iOS 26.0, macOS 26.0, *) {
                        let model = SystemLanguageModel.default
                        guard model.isAvailable else { throw Unavailable() }
                        let budget = model.contextSize - maximumResponseTokens - instructions.utf8.count / 3
                        let turns = AIConversationTurn.fitting(turns, tokens: budget)
                        guard let question = turns.last, question.role == .user else { throw Unavailable() }
                        let session = LanguageModelSession(model: model, transcript: Self.transcript(instructions, turns.dropLast()))
                        let options = GenerationOptions(maximumResponseTokens: maximumResponseTokens)
                        for try await snapshot in session.streamResponse(to: question.text, options: options) {
                            continuation.yield(snapshot.content)
                        }
                        continuation.finish()
                        return
                    }
                    #endif
                    throw Unavailable()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Thrown when the model can't answer on this device.
    struct Unavailable: Error {}

    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private static func transcript(_ instructions: String, _ history: ArraySlice<AIConversationTurn>) -> Transcript {
        func text(_ content: String) -> [Transcript.Segment] { [.text(Transcript.TextSegment(content: content))] }
        var entries: [Transcript.Entry] = [.instructions(Transcript.Instructions(segments: text(instructions), toolDefinitions: []))]
        for turn in history {
            switch turn.role {
            case .user: entries.append(.prompt(Transcript.Prompt(segments: text(turn.text))))
            case .assistant: entries.append(.response(Transcript.Response(assetIDs: [], segments: text(turn.text))))
            }
        }
        return Transcript(entries: entries)
    }
    #endif
}
