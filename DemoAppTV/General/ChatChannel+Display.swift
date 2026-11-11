//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatChannel {
    func displayName(currentUserId: UserId?) -> String {
        if let name, !name.isEmpty { return name }
        let memberNames = otherMembers(currentUserId: currentUserId).map { $0.name ?? $0.id }
        return memberNames.isEmpty ? cid.id : memberNames.joined(separator: ", ")
    }

    func avatarURL(currentUserId: UserId?) -> URL? {
        imageURL ?? otherMembers(currentUserId: currentUserId).first?.imageURL
    }

    private func otherMembers(currentUserId: UserId?) -> [ChatChannelMember] {
        lastActiveMembers.filter { $0.id != currentUserId }
    }
}
