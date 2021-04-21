//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Protocol for action item.
/// Action items are then showed in `_ChatMessageActionsView`.
/// Setup individual item by creating new instance that conforms to this protocol.
public protocol ChatMessageActionItem {
    /// Title of `ChatMessageActionItem`.
    var title: String { get }
    /// Icon of `ChatMessageActionItem`.
    var icon: UIImage { get }
    /// Marks whether `ChatMessageActionItem` is primary.
    /// Based on this property, some UI properties can be made.
    /// Default value is `false`.
    var isPrimary: Bool { get }
    /// Marks whether `ChatMessageActionItem` is destructive.
    /// Based on this property, some UI properties can be made.
    /// Default value is `false`
    var isDestructive: Bool { get }
    /// Action that should be triggered when tapping on `ChatMessageActionItem`.
    var action: (ChatMessageActionItem) -> Void { get }
}

extension ChatMessageActionItem {
    public var isPrimary: Bool { false }
    public var isDestructive: Bool { false }
}

/// Instance of `ChatMessageActionItem` for inline reply.
public struct InlineReplyActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.inlineReply }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `InlineReplyActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `InlineReplyActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionInlineReply
    }
}

/// Instance of `ChatMessageActionItem` for thread reply.
public struct ThreadReplyActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.threadReply }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `ThreadReplyActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `ThreadReplyActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionThreadReply
    }
}

/// Instance of `ChatMessageActionItem` for edit message action.
public struct EditActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.edit }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `EditActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `EditActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionEdit
    }
}

/// Instance of `ChatMessageActionItem` for copy message action.
public struct CopyActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.copy }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `CopyActionItem`
    /// - Parameters:
    ///     - action: Action to be triggered when `CopyActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionCopy
    }
}

/// Instance of `ChatMessageActionItem` for unblocking user.
public struct UnblockUserActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.userUnblock }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `UnblockUserActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `UnblockUserActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionBlockUser
    }
}

/// Instance of `ChatMessageActionItem` for blocking user.
public struct BlockUserActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.userBlock }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `BlockUserActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `BlockUserActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionBlockUser
    }
}

/// Instance of `ChatMessageActionItem` for muting user.
public struct MuteUserActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.userMute }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `MuteUserActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `MuteUserActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionMuteUser
    }
}

/// Instance of `ChatMessageActionItem` for unmuting user.
public struct UnmuteUserActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.userUnmute }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `UnmuteUserActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `UnmuteUserActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionMuteUser
    }
}

/// Instance of `ChatMessageActionItem` for deleting message action.
public struct DeleteActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.delete }
    public var isDestructive: Bool { true }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `DeleteActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `DeleteActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionDelete
    }
}

/// Instance of `ChatMessageActionItem` for resending message action.
public struct ResendActionItem: ChatMessageActionItem {
    public var title: String { L10n.Message.Actions.resend }
    public var isPrimary: Bool { true }
    public let icon: UIImage
    public let action: (ChatMessageActionItem) -> Void
    
    /// Init of `ResendActionItem`.
    /// - Parameters:
    ///     - action: Action to be triggered when `ResendActionItem` is tapped.
    ///     - uiConfig: `_UIConfig` that is used to configure UI properties.
    public init<ExtraData: ExtraDataTypes>(
        action: @escaping (ChatMessageActionItem) -> Void,
        uiConfig: _UIConfig<ExtraData> = .default
    ) {
        self.action = action
        icon = uiConfig.images.messageActionResend
    }
}
