//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AutomodDetailsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var action: String?
    var imageLabels: [String]?
    var messageDetails: FlagMessageDetailsResponse?
    var originalMessageType: String?
    var result: MessageModerationResult?

    init(action: String? = nil, imageLabels: [String]? = nil, messageDetails: FlagMessageDetailsResponse? = nil, originalMessageType: String? = nil, result: MessageModerationResult? = nil) {
        self.action = action
        self.imageLabels = imageLabels
        self.messageDetails = messageDetails
        self.originalMessageType = originalMessageType
        self.result = result
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case imageLabels = "image_labels"
        case messageDetails = "message_details"
        case originalMessageType = "original_message_type"
        case result
    }

    static func == (lhs: AutomodDetailsResponse, rhs: AutomodDetailsResponse) -> Bool {
        lhs.action == rhs.action &&
            lhs.imageLabels == rhs.imageLabels &&
            lhs.messageDetails == rhs.messageDetails &&
            lhs.originalMessageType == rhs.originalMessageType &&
            lhs.result == rhs.result
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(imageLabels)
        hasher.combine(messageDetails)
        hasher.combine(originalMessageType)
        hasher.combine(result)
    }
}
