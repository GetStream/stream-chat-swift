//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Typealias for closure taking `ChatChannel` and `UserId` which returns
/// the current name of the channel. Use this type when you create closure for naming a channel.
/// For example usage, see `DefaultChatChannelNamer`
public typealias ChatChannelNamer =
    (_ channel: ChatChannel, _ currentUserId: UserId?) -> String?

/// Generates a name for the given channel, given the current user's id.
///
/// The priority order is:
/// - Assigned name of the channel, if not empty
/// - If the channel is direct message (implicit cid):
///   - Name generated from cached members of the channel
/// - Channel's id
///
/// Examples:
/// - If channel has some name, ie. `Channel 1`, this returns `Channel 1`
/// - If channel has no name and is not direct message, this returns channel ID of the channel
/// - If channel is direct message, has no name and has members where there just 2,
/// returns name of the members in alphabetic order: `Leia, Luke`
/// - If channel is direct message, has no name and has members where there are more than 2,
/// returns name of the members in alphabetic order with how many members left: `Leia, Luke and 5 others`
///  - If channel is direct message, has no name and no members, this returns `nil`
///  - If channel is direct message, has no name and only one member, shows the one member name
///
/// - Parameters:
///   - maxMemberNames: Maximum number of visible members in Channel defaults to `2`
///   - separator: Separator of the members, defaults to `y`
/// - Returns: A closure with 2 parameters carrying `channel` used for name generation and `currentUserId` to decide
/// which members' names are going to be displayed
public func DefaultChatChannelNamer(
    maxMemberNames: Int = 2,
    separator: String = ","
) -> _ChatChannelNamer<ExtraData> {
    { channel, currentUserId in
        if let channelName = channel.name, !channelName.isEmpty {
            // If there's an assigned name and it's not empty, we use it
            return channelName
        } else if channel.isDirectMessageChannel {
            // If this is a channel generated as DM
            // we generate the name from users
            let memberNames = channel.lastActiveMembers.filter { $0.id != currentUserId }.compactMap(\.name).sorted()
            let prefixedMemberNames = memberNames.prefix(maxMemberNames)
            let channelName: String
            if prefixedMemberNames.isEmpty {
                // This channel only has current user as member
                if let currentUser = channel.lastActiveMembers.first(where: { $0.id == currentUserId }) {
                    channelName = nameOrId(currentUser.name, currentUser.id)
                } else {
                    return nil
                }
            } else {
                // This channel has exactly 2 members
                // Name it as "Darth Maul and Darth Vader
                if memberNames.count == 2 {
                    channelName = "\(prefixedMemberNames.first!) \(L10n.Channel.Name.and) \(prefixedMemberNames.last!)"
                    // This channel has more than 2 members
                    // Name it as "Darth Maul, Darth Vader and <n> more"
                } else {
                    channelName = prefixedMemberNames
                        .joined(separator: "\(separator) ")
                        + (
                            memberNames.count > maxMemberNames
                                ? " \(L10n.Channel.Name.andXMore(memberNames.count - maxMemberNames))"
                                : ""
                        )
                }
            }
            return channelName
        } else {
            // We don't have a valid name assigned, and this is not a DM channel
            // makes sense to return `nil` because `channelId` could be confusing for our users.
            return nil
        }
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
