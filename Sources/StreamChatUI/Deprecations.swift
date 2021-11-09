//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

/// - NOTE: Deprecations of the next major release.

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

extension Components {
    // MARK: - Reaction components, deprecated
    
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
