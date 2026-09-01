//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Pagination options available when paginating pinned messages.
public enum PinnedMessagesPagination: Hashable, Sendable {
    /// When used, the backend returns messages around the message with the given id.
    case aroundMessage(_ messageId: MessageId)

    /// When used, the backend returns messages pinned earlier then the message with the given id.
    ///
    /// When `inclusive == true` the results include the message with the given id.
    case before(_ messageId: MessageId, inclusive: Bool)

    /// When used, the backend returns messages pinned earlier then the message with the given id.
    ///
    /// When `inclusive == true` the results include the message with the given id.
    case after(_ messageId: MessageId, inclusive: Bool)

    /// When used, the backend returns messages pinned at around the given timestamp.
    case aroundTimestamp(_ timestamp: Date)

    /// When used, the backend returns messages pinned earlier than the given timestamp.
    ///
    /// When `inclusive == true` the results include the message pinned at the given timestamp.
    case earlier(_ timestamp: Date, inclusive: Bool)

    /// When used, the backend returns messages pinned later than the given timestamp.
    ///
    /// When `inclusive == true` the results include the message pinned at the given timestamp.
    case later(_ timestamp: Date, inclusive: Bool)

    /// When used, the backend skips the given number of pinned messages.
    case offset(_ offset: Int)
}

extension PinnedMessagesPagination {
    var aroundMessageId: MessageId? {
        if case let .aroundMessage(messageId) = self { messageId } else { nil }
    }

    var messageIdAfterOrEqual: MessageId? {
        if case let .after(messageId, true) = self { messageId } else { nil }
    }

    var messageIdAfter: MessageId? {
        if case let .after(messageId, false) = self { messageId } else { nil }
    }

    var messageIdBeforeOrEqual: MessageId? {
        if case let .before(messageId, true) = self { messageId } else { nil }
    }

    var messageIdBefore: MessageId? {
        if case let .before(messageId, false) = self { messageId } else { nil }
    }

    var aroundTimestamp: Date? {
        if case let .aroundTimestamp(timestamp) = self { timestamp } else { nil }
    }

    var timestampAfterOrEqual: Date? {
        if case let .later(timestamp, true) = self { timestamp } else { nil }
    }

    var timestampAfter: Date? {
        if case let .later(timestamp, false) = self { timestamp } else { nil }
    }

    var timestampBeforeOrEqual: Date? {
        if case let .earlier(timestamp, true) = self { timestamp } else { nil }
    }

    var timestampBefore: Date? {
        if case let .earlier(timestamp, false) = self { timestamp } else { nil }
    }

    var offset: Int? {
        if case let .offset(offset) = self { offset } else { nil }
    }
}

// MARK: - Encodable

extension PinnedMessagesPagination: Encodable {
    private enum CodingKeys: String, CodingKey {
        case id_around
        case id_gt
        case id_gte
        case id_lt
        case id_lte
        case offset
        case pinned_at_around
        case pinned_at_after
        case pinned_at_after_or_equal
        case pinned_at_before
        case pinned_at_before_or_equal
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .aroundMessage(messageId):
            try container.encode(messageId, forKey: .id_around)
        case let .after(messageId, inclusive):
            try container.encode(messageId, forKey: inclusive ? .id_gte : .id_gt)
        case let .before(messageId, inclusive):
            try container.encode(messageId, forKey: inclusive ? .id_lte : .id_lt)
        case let .aroundTimestamp(timestamp):
            try container.encode(timestamp, forKey: .pinned_at_around)
        case let .later(timestamp, inclusive):
            try container.encode(timestamp, forKey: inclusive ? .pinned_at_after_or_equal : .pinned_at_after)
        case let .earlier(timestamp, inclusive):
            try container.encode(timestamp, forKey: inclusive ? .pinned_at_before_or_equal : .pinned_at_before)
        case let .offset(offset):
            try container.encode(offset, forKey: .offset)
        }
    }
}
