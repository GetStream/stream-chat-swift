//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// The fields shared by the generated UserPayload and OwnUserResponse, which do
// not have a common base class.
protocol UserPayloadFields: Sendable {
    var avgResponseTime: Int? { get }
    var banned: Bool? { get }
    var createdAt: Date { get }
    var custom: [String: RawJSON] { get }
    var deactivatedAt: Date? { get }
    var deletedAt: Date? { get }
    var id: String { get }
    var image: String? { get }
    var language: String? { get }
    var lastActive: Date? { get }
    var name: String? { get }
    var online: Bool { get }
    var revokeTokensIssuedBefore: Date? { get }
    var role: String { get }
    var teams: [String]? { get }
    var teamsRole: [String: String]? { get }
    var updatedAt: Date { get }
}

extension OwnUserResponse: UserPayloadFields {}

extension UserPayload: UserPayloadFields {}

// Extra glue for reducing the git diff: the generated model's properties are
// slightly different from the previously hand-written UserPayload and the
// convenience init is widely used. Keep for now and clean up gradually.
extension UserPayloadFields {
    var extraData: [String: RawJSON] { custom }

    var imageURL: URL? { image.flatMap(URL.init(string:)) }

    var isBanned: Bool { banned ?? false }

    var isOnline: Bool { online }

    var lastActiveAt: Date? { lastActive }
}

extension UserPayload {
    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        avgResponseTime: Int? = nil,
        extraData: [String: RawJSON]
    ) {
        self.init(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language,
            lastActive: lastActiveAt,
            name: name,
            online: isOnline,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            updatedAt: updatedAt
        )
    }
}
