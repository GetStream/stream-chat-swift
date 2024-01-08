//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct CallTokenPayload: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case token
        case agoraUid = "agora_uid"
        case agoraAppId = "agora_app_id"
    }

    /// The call token.
    let token: String
    /// The UID related to this token (Agora only).
    let agoraUid: UInt?
    /// The Agora App Id (Agora only).
    let agoraAppId: String?

    init(token: String, agoraUid: UInt?, agoraAppId: String?) {
        self.token = token
        self.agoraUid = agoraUid
        self.agoraAppId = agoraAppId
    }
}

struct AgoraPayload: Decodable, Equatable {
    let channel: String
}

struct HMSPayload: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case roomName = "room_name"
    }

    let roomId: String
    let roomName: String
}

struct CallPayload: Decodable, Equatable {
    let id: String
    let provider: String
    let agora: AgoraPayload?
    let hms: HMSPayload?
}

struct CreateCallPayload: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case token
        case agoraUid = "agora_uid"
        case agoraAppId = "agora_app_id"
        case call
    }

    /// The call object.
    let call: CallPayload

    /// The call token.
    let token: String

    /// The UID related to this token (Agora only).
    let agoraUid: UInt?

    /// The Agora App Id (Agora only).
    let agoraAppId: String?

    init(call: CallPayload, token: String, agoraUid: UInt?, agoraAppId: String?) {
        self.call = call
        self.token = token
        self.agoraUid = agoraUid
        self.agoraAppId = agoraAppId
    }
}
