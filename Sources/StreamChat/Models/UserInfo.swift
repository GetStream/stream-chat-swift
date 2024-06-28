//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A model containing user info that's used to connect to chat's backend
public struct UserInfo {
    /// The id of the user.
    public let id: UserId
    /// The name of the user.
    public let name: String?
    /// The avatar url of the user.
    public let imageURL: URL?
    /// Whether the user wants to share his online status or not.
    public let isInvisible: Bool?
    /// The language of the user. This is required for the auto translation feature.
    public let language: TranslationLanguage?
    /// The privacy settings of the user. Example: If the user does not want to expose typing events or read events.
    public let privacySettings: UserPrivacySettings?
    /// A list of blocked user ids.
    public let blockedUserIds: [UserId]?
    /// Custom extra data of the user.
    public let extraData: [String: RawJSON]

    public init(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        isInvisible: Bool? = nil,
        language: TranslationLanguage? = nil,
        privacySettings: UserPrivacySettings? = nil,
        blockedUserIds: [UserId]? = nil,
        extraData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isInvisible = isInvisible
        self.language = language
        self.privacySettings = privacySettings
        self.blockedUserIds = blockedUserIds
        self.extraData = extraData
    }
}

/// The privacy settings of the user.
public struct UserPrivacySettings {
    /// The settings for typing indicator events.
    public var typingIndicators: TypingIndicatorPrivacySettings?
    /// The settings for the read receipt events.
    public var readReceipts: ReadReceiptsPrivacySettings?

    public init(
        typingIndicators: TypingIndicatorPrivacySettings? = nil,
        readReceipts: ReadReceiptsPrivacySettings? = nil
    ) {
        self.typingIndicators = typingIndicators
        self.readReceipts = readReceipts
    }
}

/// The settings for typing indicator events.
public struct TypingIndicatorPrivacySettings {
    public var enabled: Bool

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }
}

/// The settings for the read receipt events.
public struct ReadReceiptsPrivacySettings {
    public var enabled: Bool

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }
}
