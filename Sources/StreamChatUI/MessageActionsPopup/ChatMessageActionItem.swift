//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal struct ChatMessageActionItem<ExtraData: ExtraDataTypes> {
    internal let title: String
    internal let icon: UIImage
    internal let isPrimary: Bool
    internal let isDestructive: Bool
    internal let action: () -> Void

    internal init(
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

internal extension ChatMessageActionItem {
    static func inlineReply(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.inlineReply,
            icon: uiConfig.images.messageActionInlineReply,
            action: action
        )
    }

    static func threadReply(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.threadReply,
            icon: uiConfig.images.messageActionThreadReply,
            action: action
        )
    }

    static func edit(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.edit,
            icon: uiConfig.images.messageActionEdit,
            action: action
        )
    }

    static func copy(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData>) -> Self {
        .init(
            title: L10n.Message.Actions.copy,
            icon: uiConfig.images.messageActionCopy,
            action: action
        )
    }

    static func unblockUser(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.userUnblock,
            icon: uiConfig.images.messageActionBlockUser,
            action: action
        )
    }

    static func blockUser(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.userBlock,
            icon: uiConfig.images.messageActionBlockUser,
            action: action
        )
    }

    static func muteUser(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.userMute,
            icon: uiConfig.images.messageActionMuteUser,
            action: action
        )
    }

    static func unmuteUser(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.userUnmute,
            icon: uiConfig.images.messageActionMuteUser,
            action: action
        )
    }

    static func delete(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.delete,
            icon: uiConfig.images.messageActionDelete,
            isDestructive: true,
            action: action
        )
    }

    static func resend(action: @escaping () -> Void, uiConfig: _UIConfig<ExtraData> = .default) -> Self {
        .init(
            title: L10n.Message.Actions.resend,
            icon: uiConfig.images.messageActionResend,
            isPrimary: true,
            action: action
        )
    }
}
