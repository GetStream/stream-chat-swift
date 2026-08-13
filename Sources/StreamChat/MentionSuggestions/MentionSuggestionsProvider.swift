//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The context used to compute mention suggestions for a given query.
public struct MentionSuggestionsRequest: Sendable {
    /// The text typed after the mention symbol (e.g. `jo` for `@jo`).
    public var text: String
    /// The channel the suggestions are computed for.
    public var channel: ChatChannel

    public init(text: String, channel: ChatChannel) {
        self.text = text
        self.channel = channel
    }
}

/// A type that provides `@mention` suggestions for the composer.
///
/// Implement this protocol to fully customise how mention suggestions are
/// computed. The SDK ships two implementations:
/// - ``DefaultMentionSuggestionsProvider`` which suggests users only (legacy behaviour).
/// - ``EnhancedMentionSuggestionsProvider`` which additionally suggests
///   `@here`, `@channel`, roles and user groups.
public protocol MentionSuggestionsProvider: Sendable {
    /// Computes the mention suggestions for the given request.
    ///
    /// - Parameter request: The context describing the current mention query.
    /// - Returns: The suggestions to present, in display order.
    func mentionSuggestions(for request: MentionSuggestionsRequest) async throws -> [MentionSuggestion]

    /// Cancels any pending or in-flight suggestion searches and clears cached results.
    ///
    /// Call this when the mention query ends (for example when the user deletes `@`)
    /// so a slower, superseded search cannot surface stale suggestions.
    func clearResults() async
}

public extension MentionSuggestionsProvider {
    /// Computes the mention suggestions for the given request.
    ///
    /// Completion-based wrapper around
    /// ``mentionSuggestions(for:)-(MentionSuggestionsRequest)`` for callers that
    /// do not use Swift Concurrency.
    ///
    /// - Parameters:
    ///   - request: The context describing the current mention query.
    ///   - completion: Called with the computed suggestions or an error.
    func mentionSuggestions(
        for request: MentionSuggestionsRequest,
        completion: @escaping @Sendable (Result<[MentionSuggestion], Error>) -> Void
    ) {
        Task {
            do {
                let suggestions = try await mentionSuggestions(for: request)
                completion(.success(suggestions))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func clearResults() async {}
}
