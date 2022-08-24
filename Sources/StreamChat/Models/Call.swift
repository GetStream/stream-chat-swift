//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct CallToken {
    public let token: String
    public let agoraInfo: AgoraInfo?
}

public struct Call: Encodable {
    public let id: String
    public let provider: String
    public let agora: AgoraCall?
    public let hms: HMSCall?
}

public struct CallWithToken: Encodable {
    public let call: Call
    public let token: String
}

// HMS

public struct HMSCall: Encodable {
    public let roomId: String
    public let roomName: String
}

// Agora

public struct AgoraCall: Encodable {
    public let channel: String
    public let agoraInfo: AgoraInfo?
}

public struct AgoraInfo: Encodable {
    public let uid: UInt
    public let appId: String
}
