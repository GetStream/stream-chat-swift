//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

internal class ChatChannelNamer {
    internal var maxMemberNames: Int { 2 }
    internal var separator: String { "," }
    
    internal required init() {}
    
    /// Generates a name for the given channel, given the current user's id.
    ///
    /// The priority order is:
    /// - Assigned name of the channel, if not empty
    /// - If the channel is direct message (implicit cid):
    ///   - Name generated from cached members of the channel
    /// - Channel's id
    /// - Parameters:
    ///   - channel: Channel to generate name for.
    ///   - currentUserId: Logged-in user. This parameter is used when deciding which member's names are going to be displayed.
    /// - Returns: A valid Channel name.
    internal func name<ExtraData: ExtraDataTypes>(for channel: _ChatChannel<ExtraData>, as currentUserId: UserId?) -> String {
        if let channelName = channel.name, !channelName.isEmpty {
            // If there's an assigned name and it's not empty, we use it
            return channelName
        } else if channel.isDirectMessageChannel {
            // If this is a channel generated as DM
            // we generate the name from users
            let memberNames = channel.cachedMembers.filter { $0.id != currentUserId }.compactMap(\.name).sorted()
            let prefixedMemberNames = memberNames.prefix(maxMemberNames)
            let channelName: String
            if prefixedMemberNames.isEmpty {
                // This channel only has current user as member
                if let currentUser = channel.cachedMembers.first(where: { $0.id == currentUserId }) {
                    channelName = nameOrId(currentUser.name, currentUser.id)
                } else {
                    channelName = currentUserId ?? channel.cid.id
                }
            } else {
                // This channel has more than 2 members
                // Name it as "Luke, Leia, .. and <n> more"
                channelName = prefixedMemberNames
                    .joined(separator: "\(separator) ")
                    + (
                        memberNames.count > maxMemberNames
                            ? " \(L10n.Channel.Name.and) \(memberNames.count - maxMemberNames) \(L10n.Channel.Name.more)"
                            : ""
                    )
            }
            
            return channelName
        } else {
            // We don't have a valid name assigned, and this is not a DM channel
            // makes sense to use channel's id (so for messaging:general we'll have general)
            return channel.cid.id
        }
    }
    
    /// Entities such as `User`, `Member` and `Channel` have both `name` and `id`, and `name` is preferred for display.
    /// However, `name` and exists but can be empty, in that case we display `id`.
    /// This helper encapsulates choosing logic between `name` and `id`
    /// - Parameters:
    ///   - name: name of the entity.
    ///   - id: id of the entity
    /// - Returns: `name` if it exists and not empty, otherwise `id`
    private func nameOrId(_ name: String?, _ id: String) -> String {
        if let name = name, !name.isEmpty {
            return name
        } else {
            return id
        }
    }
}
