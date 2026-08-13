//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class SendMessageRequest: Sendable, Codable, JSONEncodable {
    /// When true, the response includes channel_context: a slim channel object with cid, type, id and created_by
    let includeChannelContext: Bool?
    /// When true, the response includes mentioned_members: for each mentioned user, whether that user is currently a channel member. Requires the ReadChannelMembers permission
    let includeMentionedMembers: Bool?
    let keepChannelHidden: Bool?
    /// Message data for creating or updating a message
    let message: MessageRequest
    let skipEnrichUrl: Bool?
    let skipPush: Bool?

    init(
        includeChannelContext: Bool? = nil,
        includeMentionedMembers: Bool? = nil,
        keepChannelHidden: Bool? = nil,
        message: MessageRequest,
        skipEnrichUrl: Bool? = nil,
        skipPush: Bool? = nil
    ) {
        self.includeChannelContext = includeChannelContext
        self.includeMentionedMembers = includeMentionedMembers
        self.keepChannelHidden = keepChannelHidden
        self.message = message
        self.skipEnrichUrl = skipEnrichUrl
        self.skipPush = skipPush
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case includeChannelContext = "include_channel_context"
        case includeMentionedMembers = "include_mentioned_members"
        case keepChannelHidden = "keep_channel_hidden"
        case message
        case skipEnrichUrl = "skip_enrich_url"
        case skipPush = "skip_push"
    }
}
