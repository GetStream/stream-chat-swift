//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class VelocityFilterConfigRule: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    enum VelocityFilterConfigRuleAction: String, Sendable, Codable, CaseIterable {
        case ban
        case flag
        case remove
        case shadow
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    enum VelocityFilterConfigRuleCascadingAction: String, Sendable, Codable, CaseIterable {
        case ban
        case flag
        case remove
        case shadow
        case unknown = "_unknown"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }

    var action: VelocityFilterConfigRuleAction
    var banDuration: Int
    var cascadingAction: VelocityFilterConfigRuleCascadingAction
    var cascadingThreshold: Int
    var checkMessageContext: Bool
    var fastSpamThreshold: Int
    var fastSpamTtl: Int
    var ipBan: Bool
    var probationPeriod: Int
    var shadowBan: Bool
    var slowSpamBanDuration: Int?
    var slowSpamThreshold: Int
    var slowSpamTtl: Int
    var urlOnly: Bool

    init(action: VelocityFilterConfigRuleAction, banDuration: Int, cascadingAction: VelocityFilterConfigRuleCascadingAction, cascadingThreshold: Int, checkMessageContext: Bool, fastSpamThreshold: Int, fastSpamTtl: Int, ipBan: Bool, probationPeriod: Int, shadowBan: Bool, slowSpamBanDuration: Int? = nil, slowSpamThreshold: Int, slowSpamTtl: Int, urlOnly: Bool) {
        self.action = action
        self.banDuration = banDuration
        self.cascadingAction = cascadingAction
        self.cascadingThreshold = cascadingThreshold
        self.checkMessageContext = checkMessageContext
        self.fastSpamThreshold = fastSpamThreshold
        self.fastSpamTtl = fastSpamTtl
        self.ipBan = ipBan
        self.probationPeriod = probationPeriod
        self.shadowBan = shadowBan
        self.slowSpamBanDuration = slowSpamBanDuration
        self.slowSpamThreshold = slowSpamThreshold
        self.slowSpamTtl = slowSpamTtl
        self.urlOnly = urlOnly
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        case banDuration = "ban_duration"
        case cascadingAction = "cascading_action"
        case cascadingThreshold = "cascading_threshold"
        case checkMessageContext = "check_message_context"
        case fastSpamThreshold = "fast_spam_threshold"
        case fastSpamTtl = "fast_spam_ttl"
        case ipBan = "ip_ban"
        case probationPeriod = "probation_period"
        case shadowBan = "shadow_ban"
        case slowSpamBanDuration = "slow_spam_ban_duration"
        case slowSpamThreshold = "slow_spam_threshold"
        case slowSpamTtl = "slow_spam_ttl"
        case urlOnly = "url_only"
    }

    static func == (lhs: VelocityFilterConfigRule, rhs: VelocityFilterConfigRule) -> Bool {
        lhs.action == rhs.action &&
            lhs.banDuration == rhs.banDuration &&
            lhs.cascadingAction == rhs.cascadingAction &&
            lhs.cascadingThreshold == rhs.cascadingThreshold &&
            lhs.checkMessageContext == rhs.checkMessageContext &&
            lhs.fastSpamThreshold == rhs.fastSpamThreshold &&
            lhs.fastSpamTtl == rhs.fastSpamTtl &&
            lhs.ipBan == rhs.ipBan &&
            lhs.probationPeriod == rhs.probationPeriod &&
            lhs.shadowBan == rhs.shadowBan &&
            lhs.slowSpamBanDuration == rhs.slowSpamBanDuration &&
            lhs.slowSpamThreshold == rhs.slowSpamThreshold &&
            lhs.slowSpamTtl == rhs.slowSpamTtl &&
            lhs.urlOnly == rhs.urlOnly
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(banDuration)
        hasher.combine(cascadingAction)
        hasher.combine(cascadingThreshold)
        hasher.combine(checkMessageContext)
        hasher.combine(fastSpamThreshold)
        hasher.combine(fastSpamTtl)
        hasher.combine(ipBan)
        hasher.combine(probationPeriod)
        hasher.combine(shadowBan)
        hasher.combine(slowSpamBanDuration)
        hasher.combine(slowSpamThreshold)
        hasher.combine(slowSpamTtl)
        hasher.combine(urlOnly)
    }
}
