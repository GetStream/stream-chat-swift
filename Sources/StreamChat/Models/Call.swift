//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct HMSCall: Encodable {
    public let roomId: String
    public let roomName: String
}

public struct AgoraCall: Encodable {
    public let channel: String
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
    public let agoraUid: UInt?
    public let agoraAppId: String?
}

public struct CallToken {
    public let token: String
    public let agoraUid: UInt?
    public let agoraAppId: String?
}
