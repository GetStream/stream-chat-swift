//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//


import Foundation

struct AcceptInviteRequest: Codable {
    let user: AcceptInviteUser
    let message: AcceptInviteMessage
    let acceptInvite: Bool
    enum CodingKeys: String, CodingKey {
        case user
        case message
        case acceptInvite = "accept_invite"
    }
}

struct AcceptInviteUser: Codable {
    let id: String
}

struct AcceptInviteMessage: Codable {
    let message: String?
}
