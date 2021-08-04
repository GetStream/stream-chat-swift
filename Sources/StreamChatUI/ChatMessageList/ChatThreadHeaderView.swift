//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays channel information on the thread header
open class ChatThreadHeaderView:
    _View,
    ThemeProvider,
    ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: ChatChannelController?

    /// The user id of the current logged in user.
    open var currentUserId: UserId? {
        channelController?.client.currentUserId
    }

    /// A view that displays a title label and subtitle in a container stack view.
    open private(set) lazy var titleContainerView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        channelController?.setDelegate(self)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(titleContainerView)
    }

    override open func updateContent() {
        super.updateContent()

        titleContainerView.content = (
            titleText,
            subtitleText
        )
    }

    /// The title text used to render the title label. By default it is "Thread Reply" label.
    open var titleText: String? {
        L10n.Message.Threads.reply
    }

    /// The subtitle text used in the subtitle label. By default it is the channel name.
    open var subtitleText: String? {
        guard let channel = channelController?.channel else { return nil }
        let channelName = components.channelNamer(channel, currentUserId)
        return channelName.map { L10n.Message.Threads.replyWith($0) }
    }

    // MARK: - ChatChannelControllerDelegate Implementation

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateChannel channel: EntityChange<ChatChannel>
    ) {
        switch channel {
        case .update:
            updateContentIfNeeded()
        default:
            break
        }
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didChangeTypingUsers typingUsers: Set<ChatUser>
    ) {
        // By default the header view is not interested in typing events
        // but this can be overridden by subclassing this component.
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didReceiveMemberEvent: Event
    ) {
        // By default the header view is not interested in member events
        // but this can be overridden by subclassing this component.
    }

    open func channelController(
        _ channelController: ChatChannelController,
        didUpdateMessages changes: [ListChange<ChatMessage>]
    ) {
        // By default the header view is not interested in message events
        // but this can be overridden by subclassing this component.
    }
}
