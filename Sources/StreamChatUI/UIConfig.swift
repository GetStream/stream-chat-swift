//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// `UIConfig` is one the main points of customaization for `StreamChatUI`.
///
/// Changes to `UIConfig.default` values are shared globally to all view in the framework. Typical appearance
/// customizations using `UIConfig` are for example:
///
/// ## Changing fonts, colors, default images, etc.
///
/// Chaning preset values in `UIConfig.default` allows you to globally modify the default for the SDK:
///
/// ```
/// UIConfig.default.fonts.title = you_custom_font
/// UIConfig.default.colorPalette.text = you_custom_text_color
/// UIConfig.images.close = you_custom_close_image
/// ```
///
/// ## Injecting custom subclasses
///
/// `UIConfig` allows you to specify which types should the framework use for when initializing its components. This makes
/// it very easy to inject your custom subclasses everywhere in the framework, no matter how deep in the hierarchy the
/// type is used:
///
/// ```
/// class CustomMessageListVC: ChatMessageListVC {
///   // ... your custom overrides
/// }
///
/// // Tell the framework to use your custom type instead of the default one
/// UIConfig.default.messageListUI.messageListVC = CustomMessageListVC.self
/// ```
///
public typealias UIConfig = _UIConfig<NoExtraData>

public struct _UIConfig<ExtraData: ExtraDataTypes> {
    /// A view used as an online activity indicator (online/offline).
    internal var onlineIndicatorView: (UIView & MaskProviding).Type = _ChatOnlineIndicatorView<ExtraData>.self

    /// A view that displays the avatar image. By default a circular image.
    internal var avatarView: ChatAvatarView.Type = ChatAvatarView.self

    /// An avatar view with an online indicator.
    internal var presenceAvatarView: _ChatPresenceAvatarView<ExtraData>.Type = _ChatPresenceAvatarView<ExtraData>.self

    internal var channelList = ChannelList()
    public var messageList = MessageListUI()
    internal var messageComposer = MessageComposer()
    internal var currentUser = CurrentUser()
    public var navigation = Navigation()
    public var colorPalette = ColorPalette()
    public var fonts = Fonts()
    public var images = Images()

    public init() {}
}

// MARK: - UIConfig + Default

private var defaults: [String: Any] = [:]

public extension _UIConfig {
    static var `default`: Self {
        get {
            log.assert(Thread.isMainThread, "`UIConfig.default` can be accessed only from the main thread.")
            let key = String(describing: ExtraData.self)
            if let existing = defaults[key] as? Self {
                return existing
            } else {
                let config = Self()
                defaults[key] = config
                return config
            }
        }
        set {
            log.assert(Thread.isMainThread, "`UIConfig.default` can be accessed only from the main thread.")
            let key = String(describing: ExtraData.self)
            defaults[key] = newValue
        }
    }
}
