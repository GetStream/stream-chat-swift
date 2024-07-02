//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum ThreadCodingKeys: String, CodingKey, CaseIterable {
    case channel
    case parentMessageId = "parent_message_id"
    case parentMessage = "parent_message"
    case createdBy = "created_by"
    case replyCount = "reply_count"
    case participantCount = "participant_count"
    case threadParticipants = "thread_participants"
    case lastMessageAt = "last_message_at"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case title
    case latestReplies = "latest_replies"
    case read
}

struct ThreadListPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case threads
        case next
    }

    let threads: [ThreadPayload]
    let next: String?

    init(threads: [ThreadPayload], next: String?) {
        self.threads = threads
        self.next = next
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let threads = try container.decodeArrayIgnoringFailures([ThreadPayload].self, forKey: .threads)
        let next = try container.decodeIfPresent(String.self, forKey: .next)

        self.threads = threads
        self.next = next
    }
}

struct ThreadPayload: Decodable {
    let parentMessageId: MessageId
    let parentMessage: MessagePayload
    let channel: ChannelDetailPayload
    let createdBy: UserPayload
    let replyCount: Int
    let participantCount: Int
    let threadParticipants: [ThreadParticipantPayload]
    let lastMessageAt: Date?
    let createdAt: Date
    let updatedAt: Date?
    let title: String?
    let latestReplies: [MessagePayload]
    let read: [ThreadReadPayload]
    let extraData: [String: RawJSON]

    init(
        parentMessageId: MessageId,
        parentMessage: MessagePayload,
        channel: ChannelDetailPayload,
        createdBy: UserPayload,
        replyCount: Int,
        participantCount: Int,
        threadParticipants: [ThreadParticipantPayload],
        lastMessageAt: Date?,
        createdAt: Date,
        updatedAt: Date?,
        title: String?,
        latestReplies: [MessagePayload],
        read: [ThreadReadPayload],
        extraData: [String: RawJSON]
    ) {
        self.parentMessageId = parentMessageId
        self.parentMessage = parentMessage
        self.channel = channel
        self.createdBy = createdBy
        self.replyCount = replyCount
        self.participantCount = participantCount
        self.threadParticipants = threadParticipants
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.latestReplies = latestReplies
        self.read = read
        self.extraData = extraData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ThreadCodingKeys.self)

        channel = try container.decode(ChannelDetailPayload.self, forKey: ThreadCodingKeys.channel)
        parentMessageId = try container.decode(String.self, forKey: ThreadCodingKeys.parentMessageId)
        parentMessage = try container.decode(MessagePayload.self, forKey: ThreadCodingKeys.parentMessage)
        createdBy = try container.decode(UserPayload.self, forKey: ThreadCodingKeys.createdBy)
        replyCount = try container.decode(Int.self, forKey: ThreadCodingKeys.replyCount)
        participantCount = try container.decode(Int.self, forKey: ThreadCodingKeys.participantCount)
        threadParticipants = try container.decodeArrayIfPresentIgnoringFailures(
            [ThreadParticipantPayload].self,
            forKey: ThreadCodingKeys.threadParticipants
        ) ?? []
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: ThreadCodingKeys.lastMessageAt)
        createdAt = try container.decode(Date.self, forKey: ThreadCodingKeys.createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: ThreadCodingKeys.updatedAt)
        title = try container.decodeIfPresent(String.self, forKey: ThreadCodingKeys.title)
        latestReplies = try container.decodeArrayIfPresentIgnoringFailures(
            [MessagePayload].self,
            forKey: ThreadCodingKeys.latestReplies
        ) ?? []
        read = try container.decodeArrayIfPresentIgnoringFailures(
            [ThreadReadPayload].self,
            forKey: ThreadCodingKeys.read
        ) ?? []

        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: ThreadCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }
    }
}

// Payload return in partial update response or thread.updated event.
struct ThreadPartialPayload: Decodable {
    let parentMessageId: MessageId
    let parentMessage: MessagePayload
    let channel: ChannelDetailPayload
    let createdBy: UserPayload
    let replyCount: Int
    let participantCount: Int
    let lastMessageAt: Date?
    let createdAt: Date
    let updatedAt: Date?
    let title: String?
    let extraData: [String: RawJSON]

    init(
        parentMessageId: MessageId,
        parentMessage: MessagePayload,
        channel: ChannelDetailPayload,
        createdBy: UserPayload,
        replyCount: Int,
        participantCount: Int,
        lastMessageAt: Date?,
        createdAt: Date,
        updatedAt: Date?,
        title: String?,
        extraData: [String: RawJSON]
    ) {
        self.parentMessageId = parentMessageId
        self.parentMessage = parentMessage
        self.channel = channel
        self.createdBy = createdBy
        self.replyCount = replyCount
        self.participantCount = participantCount
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.extraData = extraData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ThreadCodingKeys.self)

        channel = try container.decode(ChannelDetailPayload.self, forKey: ThreadCodingKeys.channel)
        parentMessageId = try container.decode(String.self, forKey: ThreadCodingKeys.parentMessageId)
        parentMessage = try container.decode(MessagePayload.self, forKey: ThreadCodingKeys.parentMessage)
        createdBy = try container.decode(UserPayload.self, forKey: ThreadCodingKeys.createdBy)
        replyCount = try container.decode(Int.self, forKey: ThreadCodingKeys.replyCount)
        participantCount = try container.decode(Int.self, forKey: ThreadCodingKeys.participantCount)
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: ThreadCodingKeys.lastMessageAt)
        createdAt = try container.decode(Date.self, forKey: ThreadCodingKeys.createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: ThreadCodingKeys.updatedAt)
        title = try container.decodeIfPresent(String.self, forKey: ThreadCodingKeys.title)

        if var payload = try? [String: RawJSON](from: decoder) {
            payload.removeValues(forKeys: ThreadCodingKeys.allCases.map(\.rawValue))
            extraData = payload
        } else {
            extraData = [:]
        }
    }
}

struct ThreadParticipantPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case user
        case threadId = "thread_id"
        case lastReadAt = "last_read_at"
        case createdAt = "created_at"
    }
    
    let user: UserPayload
    let threadId: String
    let createdAt: Date
    let lastReadAt: Date?
}

struct ThreadReadPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case user
        case lastReadAt = "last_read"
        case unreadMessagesCount = "unread_messages"
    }

    let user: UserPayload
    let lastReadAt: Date?
    let unreadMessagesCount: Int
}

// A lighter version of the Thread Payload, used for some events.
struct ThreadDetailsPayload: Decodable {
    enum CodingKeys: String, CodingKey {
        case cid = "channel_cid"
        case parentMessageId = "parent_message_id"
        case replyCount = "reply_count"
        case participantCount = "participant_count"
        case lastMessageAt = "last_message_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case title
    }

    let cid: ChannelId
    let parentMessageId: MessageId
    let replyCount: Int
    let participantCount: Int
    let lastMessageAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let title: String?
}
