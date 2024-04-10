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
    /// The private settings of the user. Example: If the user does not want to expose typing events or read events.
    public let privateSettings: UserPrivateSettings?
    /// Custom extra data of the user.
    public let extraData: [String: RawJSON]

    public init(
        id: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        isInvisible: Bool? = nil,
        language: TranslationLanguage? = nil,
        privateSettings: UserPrivateSettings? = nil,
        extraData: [String: RawJSON] = [:]
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isInvisible = isInvisible
        self.language = language
        self.privateSettings = privateSettings
        self.extraData = extraData
    }
}

/// The private settings of the user.
public struct UserPrivateSettings {
    /// The settings for typing indicator events.
    public var typingIndicators: TypingIndicatorPrivateSettings?
    /// The settings for the read receipt events.
    public var readReceipts: ReadReceiptsPrivateSettings?

    public init(
        typingIndicators: TypingIndicatorPrivateSettings? = nil,
        readReceipts: ReadReceiptsPrivateSettings? = nil
    ) {
        self.typingIndicators = typingIndicators
        self.readReceipts = readReceipts
    }
}

/// The settings for typing indicator events.
public struct TypingIndicatorPrivateSettings {
    public var enabled: Bool

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }
}

/// The settings for the read receipt events.
public struct ReadReceiptsPrivateSettings {
    public var enabled: Bool

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }
}
