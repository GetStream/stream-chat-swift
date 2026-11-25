//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The results of a unified search, one section per searched entity.
///
/// Results are snapshots and events do not update them. Channels have no members, messages, reads or unread counts.
/// Load the channel when the user opens it.
public struct UnifiedSearchResults: Sendable {
    /// Channels the current user is a member of whose name starts with the search text.
    public internal(set) var channels: UnifiedSearchSection<ChatChannel>
    /// Messages whose text matches the search text, each with its channel.
    public internal(set) var messages: UnifiedSearchSection<UnifiedSearchMessage>
    /// Users whose name or username starts with the search text.
    public internal(set) var users: UnifiedSearchSection<ChatUser>
    // Cursors are only valid for the text they were issued for, so a loaded page is
    // applied only while the results still belong to the query it was loaded for.
    let query: UnifiedSearchQuery?

    init(
        query: UnifiedSearchQuery? = nil,
        channels: UnifiedSearchSection<ChatChannel> = .init(),
        messages: UnifiedSearchSection<UnifiedSearchMessage> = .init(),
        users: UnifiedSearchSection<ChatUser> = .init()
    ) {
        self.channels = channels
        self.messages = messages
        self.query = query
        self.users = users
    }
}

/// One section of ``UnifiedSearchResults``.
public struct UnifiedSearchSection<Item: Sendable>: Sendable {
    /// The error of the last request for this section. The other sections are not affected.
    public internal(set) var error: ClientError.UnifiedSearchSectionFailed?
    /// The loaded results.
    public internal(set) var items: [Item]
    var next: String?
    // The backend rejected the cursor and returned the first page instead.
    var isRestarted: Bool

    /// Whether every result of the section is loaded.
    public var hasLoadedAll: Bool { next == nil }

    init(
        error: ClientError.UnifiedSearchSectionFailed? = nil,
        isRestarted: Bool = false,
        items: [Item] = [],
        next: String? = nil
    ) {
        self.error = error
        self.isRestarted = isRestarted
        self.items = items
        self.next = next
    }
}

/// A message which matches a unified search, together with its channel.
public struct UnifiedSearchMessage: Identifiable, Sendable {
    /// The channel of the message. It has no members, messages, reads or unread counts.
    public let channel: ChatChannel?
    /// The matching message.
    public let message: ChatMessage

    public var id: MessageId { message.id }
}

extension ClientError {
    /// A unified search section failed while the other sections succeeded.
    public final class UnifiedSearchSectionFailed: ClientError, @unchecked Sendable {
        /// The reason the section failed.
        public let code: Code

        init(code: Code, message: String) {
            self.code = code
            super.init(message)
        }
    }
}

extension ClientError.UnifiedSearchSectionFailed {
    /// The reason a unified search section failed.
    public struct Code: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension ClientError.UnifiedSearchSectionFailed.Code {
    /// The search did not finish in time. Retrying can succeed.
    public static let backendTimeout = Self(rawValue: "backend_timeout")
    /// The backend turned the search away because of load. Retry with a backoff.
    public static let backendUnavailable = Self(rawValue: "backend_unavailable")
    /// An unexpected server error.
    public static let internalError = Self(rawValue: "internal_error")
    /// The app's configuration cannot serve the section, for example when message search is disabled. Retrying does not help.
    public static let unsupported = Self(rawValue: "unsupported")
}

extension UnifiedSearchResults {
    func nextPageCursors(for entities: Set<UnifiedSearchEntity>) -> [UnifiedSearchEntity: String] {
        var cursors: [UnifiedSearchEntity: String] = [:]
        if entities.contains(.channels), let next = channels.next {
            cursors[.channels] = next
        }
        if entities.contains(.messages), let next = messages.next {
            cursors[.messages] = next
        }
        if entities.contains(.users), let next = users.next {
            cursors[.users] = next
        }
        return cursors
    }

    // A section is skipped when the results belong to another query or the section moved past the cursor,
    // such as after a newer search, clearing the results or another load of the same page.
    mutating func applyNextPage(
        _ page: UnifiedSearchResults,
        loadedFor baseQuery: UnifiedSearchQuery,
        with cursors: [UnifiedSearchEntity: String]
    ) -> Bool {
        guard query == baseQuery else { return false }
        var didChange = false
        if let cursor = cursors[.channels] {
            didChange = channels.apply(page.channels, loadedWith: cursor, id: \.cid.rawValue) || didChange
        }
        if let cursor = cursors[.messages] {
            didChange = messages.apply(page.messages, loadedWith: cursor, id: \.id) || didChange
        }
        if let cursor = cursors[.users] {
            didChange = users.apply(page.users, loadedWith: cursor, id: \.id) || didChange
        }
        return didChange
    }
}

extension UnifiedSearchSection {
    // Channel pages are offset based and channels move as they become active, so a page can repeat earlier items.
    mutating func apply(_ page: Self, loadedWith cursor: String, id: (Item) -> String) -> Bool {
        guard next == cursor else { return false }
        if let pageError = page.error {
            error = pageError
            return true
        }
        if page.isRestarted {
            items = page.items
        } else {
            let loadedIds = Set(items.map(id))
            items += page.items.filter { !loadedIds.contains(id($0)) }
        }
        error = nil
        next = page.next
        return true
    }
}
