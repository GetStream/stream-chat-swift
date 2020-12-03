//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ChatMessageActionItem {
    public let title: String
    public let icon: UIImage
    public let isDestructive: Bool
    public let action: () -> Void

    public init(
        title: String,
        icon: UIImage,
        isDestructive: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }
}

public extension ChatMessageActionItem {
    static func inlineReply(action: @escaping () -> Void) -> Self {
        .init(
            title: "Reply",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func threadReply(action: @escaping () -> Void) -> Self {
        .init(
            title: "Thread Reply",
            icon: UIImage(named: "icn_thread_reply", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func edit(action: @escaping () -> Void) -> Self {
        .init(
            title: "Edit",
            icon: UIImage(named: "icn_edit", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func copy(action: @escaping () -> Void) -> Self {
        .init(
            title: "Copy Message",
            icon: UIImage(named: "icn_copy", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func unblockUser(action: @escaping () -> Void) -> Self {
        .init(
            title: "Unblock User",
            icon: UIImage(named: "icn_block_user", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func blockUser(action: @escaping () -> Void) -> Self {
        .init(
            title: "Block User",
            icon: UIImage(named: "icn_block_user", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func muteUser(action: @escaping () -> Void) -> Self {
        .init(
            title: "Mute User",
            icon: UIImage(named: "icn_mute_user", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func unmuteUser(action: @escaping () -> Void) -> Self {
        .init(
            title: "Unmute User",
            icon: UIImage(named: "icn_mute_user", in: .streamChatUI)!,
            isDestructive: false,
            action: action
        )
    }

    static func delete(action: @escaping () -> Void) -> Self {
        .init(
            title: "Delete Message",
            icon: UIImage(named: "icn_delete", in: .streamChatUI)!,
            isDestructive: true,
            action: action
        )
    }
}
