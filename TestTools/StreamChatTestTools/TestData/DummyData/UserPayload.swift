//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

typealias CurrentUserUpdateResponse = UpdateUsersResponse
typealias UserListPayload = QueryUsersResponse

// The generated model's properties are slightly different from the previously
// hand-written UserPayload. These wrappers keep the existing tests compiling
// without rewriting them.
extension UserPayload {
    var extraData: [String: RawJSON] { custom }

    var imageURL: URL? { image.flatMap(URL.init(string:)) }

    var isBanned: Bool { banned ?? false }

    var isOnline: Bool { online }

    var lastActiveAt: Date? { lastActive }
}

extension UserPayload {
    /// Returns a dummy user payload with the given `id` and `extraData`
    static func dummy(
        userId: UserId,
        name: String? = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        teamsRole: [String: UserRole]? = nil,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        language: String? = nil,
        avgResponseTime: Int? = nil,
        isOnline: Bool = true,
        isBanned: Bool = false,
        createdAt: Date = .unique,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil,
        lastActiveAt: Date? = .unique
    ) -> UserPayload {
        .init(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            id: userId,
            image: imageUrl?.absoluteString,
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

extension CurrentUserPayload {
    static func dummy(
        userId: UserId,
        name: String = .unique,
        imageUrl: URL? = .unique(),
        role: UserRole = .admin,
        teamsRole: [String: UserRole]? = nil,
        extraData: [String: RawJSON] = [:],
        teams: [TeamId] = [.unique, .unique, .unique],
        language: String? = nil,
        isBanned: Bool = false,
        updatedAt: Date = .unique,
        deactivatedAt: Date? = nil,
        privacySettings: UserPrivacySettings? = nil
    ) -> CurrentUserPayload {
        .init(
            id: userId,
            name: name,
            imageURL: imageUrl,
            role: role,
            teamsRole: teamsRole,
            createdAt: .unique,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: .unique,
            isOnline: true,
            isInvisible: true,
            isBanned: isBanned,
            teams: teams,
            language: language,
            extraData: extraData,
            privacySettings: privacySettings ?? .init(
                typingIndicators: .init(enabled: true),
                readReceipts: .init(enabled: true),
                deliveryReceipts: .init(enabled: true)
            ),
            pushPreference: nil
        )
    }
}
