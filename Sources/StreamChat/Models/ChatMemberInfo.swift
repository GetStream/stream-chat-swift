//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Slim channel-member information attached to messages, mentions, and typing events.
///
/// This is not a full ``ChatChannelMember``. Known fields such as role and notification
/// mute state are exposed as typed properties; any additional fields land in ``extraData``.
///
/// Distinct from ``MemberInfo``, which is the payload used when adding members to a channel.
public struct ChatMemberInfo: Hashable, Sendable {
    /// The role of the member in the channel.
    public let channelRole: MemberRole?
    /// Whether the member has muted notifications for the channel.
    public let notificationsMuted: Bool
    /// Additional inline fields from the channel membership.
    public let extraData: [String: RawJSON]

    init(
        channelRole: MemberRole? = nil,
        notificationsMuted: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) {
        self.channelRole = channelRole
        self.notificationsMuted = notificationsMuted
        self.extraData = extraData
    }
}
