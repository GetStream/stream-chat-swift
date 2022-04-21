//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

// swiftlint:disable all

/// - NOTE: Deprecations of the next major release.

public extension ChatMessageLayoutOptionsResolver {
    @available(
        *,
        deprecated,
        message: "this propery should have been called `maxTimeIntervalBetweenMessagesInGroup` as it describes the maximum time interval between 2 consecutive messages when they can still be groped. Please use `maxTimeIntervalBetweenMessagesInGroup` instead."
    )
    var minTimeIntervalBetweenMessagesInGroup: TimeInterval {
        maxTimeIntervalBetweenMessagesInGroup
    }
    
    @available(
        *,
        deprecated,
        message: "this init should have been called `init(maxTimeIntervalBetweenMessagesInGroup:)` as it requires the maximum time interval between 2 consecutive messages can still can be groped. Please use `init(maxTimeIntervalBetweenMessagesInGroup:)` instead."
    )
    convenience init(minTimeIntervalBetweenMessagesInGroup: TimeInterval) {
        self.init(maxTimeIntervalBetweenMessagesInGroup: minTimeIntervalBetweenMessagesInGroup)
    }
}

@available(*, deprecated, renamed: "ChatMessageActionsTransitionController")
public typealias MessageActionsTransitionController = ChatMessageActionsTransitionController

@available(*, deprecated, renamed: "VideoLoading")
public typealias VideoPreviewLoader = VideoLoading

public extension Components {
    @available(*, deprecated, renamed: "videoLoader")
    var videoPreviewLoader: VideoLoading {
        get { videoLoader }
        set { videoLoader = newValue }
    }
}

// MARK: - `setDelegate()` deprecations.

public extension ChatUserSearchController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatUserSearchControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatMessageSearchController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatMessageSearchControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatUserController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatUserControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatChannelMemberController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatChannelMemberControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatChannelMemberListController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatChannelMemberListControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatChannelWatcherListController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatChannelWatcherListControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatChannelController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatChannelControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension ChatChannelListController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatChannelListControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

public extension CurrentChatUserController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: CurrentChatUserControllerDelegate>(_ delegate: Delegate?) {
        self.delegate = delegate
    }
}

public extension ChatConnectionController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatConnectionControllerDelegate>(_ delegate: Delegate?) {
        self.delegate = delegate
    }
}

public extension ChatUserListController {
    @available(*, deprecated, message: "the `delegate` property should be used directly instead.")
    func setDelegate<Delegate: ChatUserListControllerDelegate>(_ delegate: Delegate) {
        self.delegate = delegate
    }
}

extension ChatMessageReactionsView {
    @available(*, deprecated, message: "Use ChatMessageReactionItemView instead")
    public typealias ItemView = ChatMessageReactionItemView
}

@available(*, deprecated, message: "Use ChatReactionPickerBubbleView instead")
public typealias ChatMessageReactionsBubbleView = ChatReactionPickerBubbleView

@available(*, deprecated, message: "Use DefaultChatReactionPickerBubbleView instead")
public typealias ChatMessageDefaultReactionsBubbleView = DefaultChatReactionPickerBubbleView

// MARK: - Reaction components, deprecated

extension Components {
    @available(*, deprecated, message: "Use reactionPickerVC instead")
    public var messageReactionsVC: ChatMessageReactionsVC.Type {
        get {
            reactionPickerVC
        }
        set {
            reactionPickerVC = newValue
        }
    }

    @available(*, deprecated, message: "Use messageReactionsBubbleView instead")
    public var chatReactionsBubbleView: ChatReactionBubbleBaseView.Type {
        get {
            messageReactionsBubbleView
        }
        set {
            messageReactionsBubbleView = newValue
        }
    }

    @available(*, deprecated, message: "Use reactionPickerBubbleView instead")
    public var reactionsBubbleView: ChatReactionPickerBubbleView.Type {
        get {
            reactionPickerBubbleView
        }
        set {
            reactionPickerBubbleView = newValue
        }
    }

    @available(*, deprecated, message: "Use reactionPickerReactionsView and/or messageReactionsView")
    public var reactionsView: ChatMessageReactionsView.Type {
        get {
            reactionPickerReactionsView
        }
        set {
            reactionPickerReactionsView = newValue
            messageReactionsView = newValue
        }
    }

    @available(*, deprecated, message: "Use reactionPickerReactionItemView and/or messageReactionItemView")
    public var reactionItemView: ChatMessageReactionItemView.Type {
        get {
            reactionPickerReactionItemView
        }
        set {
            reactionPickerReactionItemView = newValue
            messageReactionItemView = newValue
        }
    }
}

// MARK: - Deprecation of ChatMessageLayoutOptions as an OptionSet

/// Previously `ChatMessageLayoutOptions` was an `OptionSet`, this limited the customization on
/// the customer side because the raw value needs to be an `Int`. A more flexible approach is to just
/// have a `Set` of `ChatMessageLayoutOption`. So for backwards compatibility we created the following
/// typealias `typealias = Set<ChatMessageLayoutOption>` and provided an API like the `OptionSet` so we
/// don't break the public API.

public extension ChatMessageLayoutOptions {
    @available(*, deprecated, message: "use `id` instead.")
    var rawValue: String {
        id
    }

    @available(*, deprecated, message: "use `subtracting(_ other: Sequence)` instead.")
    mutating func subtracting(_ option: ChatMessageLayoutOption) {
        self = subtracting([option])
    }

    @available(*, deprecated, message: "use `intersection(_ other: Sequence)` instead.")
    mutating func intersection(_ option: ChatMessageLayoutOption) {
        self = intersection([option])
    }

    @available(*, deprecated, message: """
        use `contains(_ member: ChatMessageLayoutOption` instead. And make sure the custom option is being extended in
        `ChatMessageLayoutOption` and not in `ChatMessageLayoutOptions`.
    """)
    func contains(_ options: ChatMessageLayoutOptions) -> Bool {
        options.isSubset(of: self)
    }

    @available(*, deprecated, message: """
        ChatMessageLayoutOptions is not an OptionSet anymore. Extend ChatMessageLayoutOption to create new options.
        Use the string raw value initialiser from `ChatMessageLayoutOption` instead of `ChatMessageLayoutOptions`.
    """)
    init(rawValue: Int) {
        let option = ChatMessageLayoutOption(rawValue: "\(rawValue)")
        self = Set(arrayLiteral: option)
    }
}

// MARK: - Refactoring of message list date separator

extension ChatMessageListScrollOverlayView {
    @available(*, deprecated, message: "use `dateSeparatorView.textLabel` instead.")
    open var textLabel: UILabel {
        dateSeparatorView.textLabel
    }
}

// MARK: - Formatters

extension DateFormatter {
    @available(
        *,
        deprecated,
        message: "Please use `Appearance.default.formatters.messageDateSeparator` instead"
    )
    public static var messageListDateOverlay: DateFormatter {
        DefaultMessageDateSeparatorFormatter().dateFormatter
    }
}

// MARK: AttachmentsPreviewVC - Mixed Attachments Support

extension AttachmentsPreviewVC {
    @available(
        *,
        deprecated,
        message: "this view has been split into 2 views, horizontalScrollView and verticalScrollView. This change was required to support mixed attachments. We highly recommend stopping using this view since with mixed attachments the customization done to this view won't affect both scroll views."
    )
    open var scrollView: UIScrollView {
        let axises = Set(content.map { type(of: $0).preferredAxis })
        if axises.contains(.horizontal) {
            return horizontalScrollView
        }
        return verticalScrollView
    }

    @available(*, deprecated, renamed: "verticalScrollViewHeightConstraint")
    public var scrollViewHeightConstraint: NSLayoutConstraint? {
        get { verticalScrollViewHeightConstraint }
        set { verticalScrollViewHeightConstraint = newValue }
    }

    @available(
        *,
        deprecated,
        message: "this property is not being used anymore by default. There's now two scroll views for each axis."
    )
    open var stackViewAxis: NSLayoutConstraint.Axis {
        content.first.flatMap { type(of: $0).preferredAxis } ?? .horizontal
    }

    @available(
        *,
        deprecated,
        message: "it has been replaced by attachmentPreviews(for:). The name reflects better the intent and when asking for the attachment views, it is safer to specify which axis or axises we want."
    )
    open var attachmentViews: [UIView] {
        attachmentPreviews(for: [.horizontal, .vertical])
    }
}
