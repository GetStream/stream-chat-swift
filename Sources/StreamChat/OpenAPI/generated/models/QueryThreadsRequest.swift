//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryThreadsRequest: Codable, Hashable {
    public var connectionId: String? = nil
    public var limit: Int? = nil
    public var next: String? = nil
    public var participantLimit: Int? = nil
    public var prev: String? = nil
    public var replyLimit: Int? = nil
    public var watch: Bool? = nil

    public init(connectionId: String? = nil, limit: Int? = nil, next: String? = nil, participantLimit: Int? = nil, prev: String? = nil, replyLimit: Int? = nil, watch: Bool? = nil) {
        self.connectionId = connectionId
        self.limit = limit
        self.next = next
        self.participantLimit = participantLimit
        self.prev = prev
        self.replyLimit = replyLimit
        self.watch = watch
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
        case limit
        case next
        case participantLimit = "participant_limit"
        case prev
        case replyLimit = "reply_limit"
        case watch
    }
}
