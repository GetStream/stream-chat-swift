//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ChatPreferencesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channelMentions: String?
    var defaultPreference: String?
    var directMentions: String?
    var groupMentions: String?
    var hereMentions: String?
    var roleMentions: String?
    var threadReplies: String?

    init(channelMentions: String? = nil, defaultPreference: String? = nil, directMentions: String? = nil, groupMentions: String? = nil, hereMentions: String? = nil, roleMentions: String? = nil, threadReplies: String? = nil) {
        self.channelMentions = channelMentions
        self.defaultPreference = defaultPreference
        self.directMentions = directMentions
        self.groupMentions = groupMentions
        self.hereMentions = hereMentions
        self.roleMentions = roleMentions
        self.threadReplies = threadReplies
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channelMentions = "channel_mentions"
        case defaultPreference = "default_preference"
        case directMentions = "direct_mentions"
        case groupMentions = "group_mentions"
        case hereMentions = "here_mentions"
        case roleMentions = "role_mentions"
        case threadReplies = "thread_replies"
    }

    static func == (lhs: ChatPreferencesResponse, rhs: ChatPreferencesResponse) -> Bool {
        lhs.channelMentions == rhs.channelMentions &&
            lhs.defaultPreference == rhs.defaultPreference &&
            lhs.directMentions == rhs.directMentions &&
            lhs.groupMentions == rhs.groupMentions &&
            lhs.hereMentions == rhs.hereMentions &&
            lhs.roleMentions == rhs.roleMentions &&
            lhs.threadReplies == rhs.threadReplies
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channelMentions)
        hasher.combine(defaultPreference)
        hasher.combine(directMentions)
        hasher.combine(groupMentions)
        hasher.combine(hereMentions)
        hasher.combine(roleMentions)
        hasher.combine(threadReplies)
    }
}
