//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallToken: Equatable, Sendable {
    public let token: String
    public let agoraInfo: AgoraInfo?
}

public struct Call: Encodable, Equatable, Sendable {
    public let id: String
    public let provider: String
    public let agora: AgoraCall?
    public let hms: HMSCall?
}

public struct CallWithToken: Encodable, Equatable, Sendable {
    public let call: Call
    public let token: String
}

// HMS

public struct HMSCall: Encodable, Equatable, Sendable {
    public let roomId: String
    public let roomName: String
}

// Agora

public struct AgoraCall: Encodable, Equatable, Sendable {
    public let channel: String
    public let agoraInfo: AgoraInfo?
}

public struct AgoraInfo: Encodable, Equatable, Sendable {
    public let uid: UInt
    public let appId: String
}
