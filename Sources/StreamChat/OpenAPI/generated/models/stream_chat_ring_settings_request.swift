//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRingSettingsRequest: Codable, Hashable {
    public var autoCancelTimeoutMs: Int?
    
    public var incomingCallTimeoutMs: Int?
    
    public init(autoCancelTimeoutMs: Int?, incomingCallTimeoutMs: Int?) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoCancelTimeoutMs = "auto_cancel_timeout_ms"
        
        case incomingCallTimeoutMs = "incoming_call_timeout_ms"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoCancelTimeoutMs, forKey: .autoCancelTimeoutMs)
        
        try container.encode(incomingCallTimeoutMs, forKey: .incomingCallTimeoutMs)
    }
}
