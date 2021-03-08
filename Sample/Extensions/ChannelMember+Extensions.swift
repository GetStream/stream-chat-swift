//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

/// Creates formatted string for channel member online status.
///
/// Example result: `online` or `4 min ago`
func createMemberOnlineStatusInfoString(for member: ChatChannelMember) -> String? {
    if member.isOnline {
        return "online"
    } else {
        return member.lastActiveAt?.timeAgo
    }
}

/// Creates formatted string for channel member name and ban status.
///
/// Example result: `Luke Skywalker`, or `Luke Skywalker 🚫`, or `Luke Skywalker (You)` for the current user.
func createMemberNameAndStatusInfoString(for member: ChatChannelMember, isCurrentUser: Bool) -> String {
    let name = member.name ?? "No name"
    let banIcon = member.isBanned ? "🚫" : ""
    
    let nameInfo: String
    if isCurrentUser {
        nameInfo = "\(name) (You)"
    } else {
        nameInfo = name
    }
    
    return [nameInfo, banIcon].joined(separator: " ")
}

/// Creates member role string for channel member if it differs from `.member`.
func createMemberRoleString(for member: ChatChannelMember) -> String? {
    member.memberRole != .member ? member.memberRole.rawValue : nil
}
