//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Common fields shared by all generated user response models so that user data
/// can be persisted and converted to domain models without intermediate copies.
protocol UserResponseFields: Sendable {
    var id: String { get }
    var name: String? { get }
    var image: String? { get }
    var banned: Bool { get }
    var online: Bool { get }
    var role: String { get }
    var teamsRole: [String: String]? { get }
    var language: String { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var deactivatedAt: Date? { get }
    var lastActive: Date? { get }
    var teams: [String]? { get }
    var avgResponseTime: Int? { get }
    var custom: [String: RawJSON] { get }
}

extension FullUserResponse: UserResponseFields {}
extension OwnUserResponse: UserResponseFields {}
extension UserResponse: UserResponseFields {}
extension UserResponseCommonFields: UserResponseFields {}
extension UserResponsePrivacyFields: UserResponseFields {}

extension UserResponseFields {
    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }

    var teamsUserRole: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }
}

extension CreateGuestResponse {
    func validatedToken() throws -> Token {
        let token = try Token(rawValue: accessToken)
        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }
        return token
    }
}

extension FullUserResponse {
    func asOwnUserResponse() -> OwnUserResponse {
        OwnUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            channelMutes: channelMutes,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            devices: devices,
            id: id,
            image: image,
            invisible: invisible,
            language: language,
            lastActive: lastActive,
            latestHiddenChannels: latestHiddenChannels,
            mutes: mutes,
            name: name,
            online: online,
            privacySettings: privacySettings,
            pushPreferences: nil,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: totalUnreadCount,
            unreadChannels: unreadChannels,
            unreadCount: unreadCount,
            unreadThreads: unreadThreads,
            updatedAt: updatedAt
        )
    }
}

extension OwnUserResponse {
    var unreadCountPayload: UnreadCountPayload? {
        UnreadCountPayload(
            channels: unreadChannels,
            messages: unreadCount,
            threads: unreadThreads >= 0 ? unreadThreads : nil
        )
    }
}

extension UserPrivacySettings {
    var asPrivacySettingsResponse: PrivacySettingsResponse {
        PrivacySettingsResponse(
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) }
        )
    }
}
