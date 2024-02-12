//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct AutomodDetails: Codable, Hashable {
    public var action: String? = nil
    public var originalMessageType: String? = nil
    public var imageLabels: [String]? = nil
    public var messageDetails: FlagMessageDetails? = nil
    public var result: MessageModerationResult? = nil

    public init(action: String? = nil, originalMessageType: String? = nil, imageLabels: [String]? = nil, messageDetails: FlagMessageDetails? = nil, result: MessageModerationResult? = nil) {
        self.action = action
        self.originalMessageType = originalMessageType
        self.imageLabels = imageLabels
        self.messageDetails = messageDetails
        self.result = result
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case originalMessageType = "original_message_type"
        case imageLabels = "image_labels"
        case messageDetails = "message_details"
        case result
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(originalMessageType, forKey: .originalMessageType)
        try container.encode(imageLabels, forKey: .imageLabels)
        try container.encode(messageDetails, forKey: .messageDetails)
        try container.encode(result, forKey: .result)
    }
}
