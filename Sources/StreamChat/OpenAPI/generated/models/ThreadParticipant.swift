//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ThreadParticipant: Codable, Hashable {
    public var appPk: Int
    public var channelCid: String
    public var createdAt: Date
    public var custom: [String: RawJSON]
    public var leftThreadAt: Date? = nil
    public var threadId: String? = nil
    public var userId: String? = nil
    public var user: UserObject? = nil

    public init(appPk: Int, channelCid: String, createdAt: Date, custom: [String: RawJSON], leftThreadAt: Date? = nil, threadId: String? = nil, userId: String? = nil, user: UserObject? = nil) {
        self.appPk = appPk
        self.channelCid = channelCid
        self.createdAt = createdAt
        self.custom = custom
        self.leftThreadAt = leftThreadAt
        self.threadId = threadId
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case appPk = "app_pk"
        case channelCid = "channel_cid"
        case createdAt = "created_at"
        case custom = "Custom"
        case leftThreadAt = "left_thread_at"
        case threadId = "thread_id"
        case userId = "user_id"
        case user
    }
}
