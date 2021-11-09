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
