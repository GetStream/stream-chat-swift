//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ChatMessageActionItem {
    public let title: String
    public let icon: UIImage
    public let isPrimary: Bool
    public let isDestructive: Bool
    public let action: () -> Void

    public init(
        title: String,
        icon: UIImage,
        isPrimary: Bool = false,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isPrimary = isPrimary
        self.isDestructive = isDestructive
        self.action = action
    }
}

public extension ChatMessageActionItem {
    static func inlineReply(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.inlineReply,
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            action: action
        )
    }

    static func threadReply(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.threadReply,
            icon: UIImage(named: "icn_thread_reply", in: .streamChatUI)!,
            action: action
        )
    }

    static func edit(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.edit,
            icon: UIImage(named: "icn_edit", in: .streamChatUI)!,
            action: action
        )
    }

    static func copy(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.copy,
            icon: UIImage(named: "icn_copy", in: .streamChatUI)!,
            action: action
        )
    }

    static func unblockUser(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.userUnblock,
            icon: UIImage(named: "icn_block_user", in: .streamChatUI)!,
            action: action
        )
    }

    static func blockUser(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.userBlock,
            icon: UIImage(named: "icn_block_user", in: .streamChatUI)!,
            action: action
        )
    }

    static func muteUser(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.userMute,
            icon: UIImage(named: "icn_mute_user", in: .streamChatUI)!,
            action: action
        )
    }

    static func unmuteUser(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.userUnmute,
            icon: UIImage(named: "icn_mute_user", in: .streamChatUI)!,
            action: action
        )
    }

    static func delete(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.delete,
            icon: UIImage(named: "icn_delete", in: .streamChatUI)!,
            isDestructive: true,
            action: action
        )
    }

    static func resend(action: @escaping () -> Void) -> Self {
        .init(
            title: L10n.Message.Actions.resend,
            icon: UIImage(named: "icn_resend", in: .streamChatUI)!,
            isPrimary: true,
            action: action
        )
    }
}
