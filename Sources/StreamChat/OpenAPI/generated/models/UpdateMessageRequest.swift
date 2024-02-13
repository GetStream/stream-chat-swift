//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateMessageRequest: Codable, Hashable {
    public var message: MessageRequest
    public var skipEnrichUrl: Bool? = nil

    public init(message: MessageRequest, skipEnrichUrl: Bool? = nil) {
        self.message = message
        self.skipEnrichUrl = skipEnrichUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        case skipEnrichUrl = "skip_enrich_url"
    }
}
