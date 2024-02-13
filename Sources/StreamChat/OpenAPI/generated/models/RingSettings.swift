//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct RingSettings: Codable, Hashable {
    public var autoCancelTimeoutMs: Int
    public var incomingCallTimeoutMs: Int

    public init(autoCancelTimeoutMs: Int, incomingCallTimeoutMs: Int) {
        self.autoCancelTimeoutMs = autoCancelTimeoutMs
        self.incomingCallTimeoutMs = incomingCallTimeoutMs
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoCancelTimeoutMs = "auto_cancel_timeout_ms"
        case incomingCallTimeoutMs = "incoming_call_timeout_ms"
    }
}
