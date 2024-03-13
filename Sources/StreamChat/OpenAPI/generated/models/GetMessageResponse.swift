//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GetMessageResponse: Codable, Hashable {
    public var duration: String
    public var message: MessageWithChannelResponse
    public var pendingMessageMetadata: [String: String]? = nil

    public init(duration: String, message: MessageWithChannelResponse, pendingMessageMetadata: [String: String]? = nil) {
        self.duration = duration
        self.message = message
        self.pendingMessageMetadata = pendingMessageMetadata
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case message
        case pendingMessageMetadata = "pending_message_metadata"
    }
}
