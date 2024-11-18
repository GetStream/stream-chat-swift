//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the details of a message which was moderated.
public struct MessageModerationDetails {
    /// The original message text.
    public let originalText: String
    /// The type of moderation performed to a message.
    public let action: MessageModerationAction
    /// Array of harm labels found in text.
    public let textHarms: [ModerationHarm]?
    /// Array of harm labels found in images.
    public let imageHarms: [ModerationHarm]?
    /// Blocklist name that was matched.
    public let blocklistMatched: String?
    /// Semantic filter phrase that was matched.
    public let semanticFilterMatched: String?
    /// A boolean value indicating if the message triggered the platform circumvention model.
    public let platformCircumvented: Bool?
}

/// The type of moderation performed to a message.
public struct MessageModerationAction: Equatable {
    let rawValue: String

    internal init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The message was bounced message, which means it needs to be rephrased and sent again.
    public static let bounce = Self(rawValue: "bounce")
    /// The message was blocked and removed from the chat.
    public static let remove = Self(rawValue: "remove")
}

public typealias ModerationHarm = String

public extension ModerationHarm {
    static let thread: Self = "THREAT"
    static let sexualHarassment: Self = "SEXUAL_HARASSMENT"
    static let moralHarassment: Self = "MORAL_HARASSMENT"
    static let selfHarm: Self = "SELF_HARM"
    static let terrorism: Self = "TERRORISM"
    static let racism: Self = "RACISM"
    static let lgbtqiaPlusPhobia: Self = "LGBTQIAPLUS_PHOBIA"
    static let misogyny: Self = "MISOGYNY"
    static let ableism: Self = "ABLEISM"
    static let pedophilia: Self = "PEDOPHILIA"
    static let insult: Self = "INSULT"
    static let hatred: Self = "HATRED"
    static let bodyShaming: Self = "BODY_SHAMING"
    static let trolling: Self = "TROLLING"
    static let doxxing: Self = "DOXXING"
    static let vulgarity: Self = "VULGARITY"
    static let sexuallyExplicit: Self = "SEXUALLY_EXPLICIT"
    static let drugExplicit: Self = "DRUG_EXPLICIT"
    static let weaponExplicit: Self = "WEAPON_EXPLICIT"
    static let dating: Self = "DATING"
    static let reputationHarm: Self = "REPUTATION_HARM"
    static let ads: Self = "ADS"
    static let useless: Self = "USELESS"
    static let scam: Self = "SCAM"
    static let spam: Self = "SPAM"
    static let flood: Self = "FLOOD"
    static let pii: Self = "PII"
    static let underageUser: Self = "UNDERAGE_USER"
    static let link: Self = "LINK"
    static let geopolitical: Self = "GEOPOLITICAL"
    static let negativeCriticism: Self = "NEGATIVE_CRITICISM"
    static let terrorismReference: Self = "TERRORISM_REFERENCE"
    static let boycott: Self = "BOYCOTT"
    static let politics: Self = "POLITICS"
}
