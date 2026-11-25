//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A section of a unified search.
public struct UnifiedSearchEntity: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension UnifiedSearchEntity {
    /// Channels the current user is a member of whose name starts with the search text, most recently active first.
    public static let channels = UnifiedSearchEntity(rawValue: "channels")
    /// Messages whose text matches the search text, newest first.
    public static let messages = UnifiedSearchEntity(rawValue: "messages")
    /// Users whose name or username starts with the search text, most recently created first.
    public static let users = UnifiedSearchEntity(rawValue: "users")
}

/// A query which searches messages, users and channels with one request.
///
/// The backend picks the match operator, the sort order and the scope of every section, so the query has no filter or sort.
public struct UnifiedSearchQuery: Equatable, Sendable {
    /// The sections to search.
    public let entities: Set<UnifiedSearchEntity>
    /// The number of results to load per section, between 1 and 30.
    public let pageSize: Int
    /// The search text without leading and trailing whitespace, up to 80 characters.
    public let text: String

    /// Creates a unified search query.
    ///
    /// - Parameters:
    ///   - text: The search text. Leading and trailing whitespace is removed. The backend rejects text longer than 80 characters.
    ///   - entities: The sections to search. Defaults to all sections.
    ///   - pageSize: The number of results to load per section, between 1 and 30. Defaults to 10.
    public init(
        text: String,
        entities: Set<UnifiedSearchEntity> = [.channels, .messages, .users],
        pageSize: Int = 10
    ) {
        self.entities = entities
        self.pageSize = pageSize
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension UnifiedSearchQuery {
    func asRequest(cursors: [UnifiedSearchEntity: String] = [:]) -> SearchAllRequest {
        SearchAllRequest(
            entities: entities.map(\.rawValue).sorted(),
            limit: pageSize,
            next: cursors.isEmpty ? nil : Dictionary(uniqueKeysWithValues: cursors.map { ($0.key.rawValue, $0.value) }),
            query: text
        )
    }
}
