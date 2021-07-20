//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays channel information on the message list header
public typealias ChatMessageListHeaderView = _ChatMessageListHeaderView<NoExtraData>

/// The view that displays channel information on the message list header
open class _ChatMessageListHeaderView<ExtraData: ExtraDataTypes>:
    _View,
    ThemeProvider,
    _ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: _ChatChannelController<ExtraData>?

    /// The user id of the current logged in user.
    open var currentUserId: UserId? {
        client?.currentUserId
    }

    /// The chat client instance provided by the channel controller.
    open var client: _ChatClient<ExtraData>? {
        channelController?.client
    }

    /// Timer used to update the online status of member in the chat channel.
    open var timer: Timer?

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

        titleContainerView.content = (titleText, subtitleText)

        /// If the channel is direct between two people, call update content
        /// repeatedly every minute to update the online status of the members.
        if timer == nil, channelController?.channel?.isDirectMessageChannel == true {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.updateContentIfNeeded()
            }
        } else {
            timer = nil
        }
    }

    /// The title text used to render the title label
    open var titleText: String? {
        guard let channel = channelController?.channel else { return nil }
        return components.channelNamer(channel, client?.currentUserId)
    }

    /// The subtitle text used to render subtitle label
    open var subtitleText: String? {
        guard let channel = channelController?.channel else { return nil }
        guard let currentUserId = self.currentUserId else { return nil }

        if channel.isDirectMessageChannel {
            guard let member = channel
                .lastActiveMembers
                .first(where: { $0.id != currentUserId })
            else {
                return nil
            }

            if member.isOnline {
                return L10n.Message.Title.online
            } else if let minutes = member.lastActiveAt
                .flatMap({ DateComponentsFormatter.minutes.string(from: $0, to: Date()) }) {
                return L10n.Message.Title.seeMinutesAgo(minutes)
            } else {
                return L10n.Message.Title.offline
            }
        }

        return L10n.Message.Title.group(channel.memberCount, channel.watcherCount)
    }

    // MARK: - _ChatChannelControllerDelegate Implementation

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        switch channel {
        case .update:
            updateContentIfNeeded()
        default:
            break
        }
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingUsers typingUsers: Set<_ChatUser<ExtraData.User>>
    ) {
        // By default the header view is not interested in typing events
        // but this can be overridden by subclassing this component.
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didReceiveMemberEvent: MemberEvent
    ) {
        // By default the header view is not interested in member events
        // but this can be overridden by subclassing this component.
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        // By default the header view is not interested in message events
        // but this can be overridden by subclassing this component.
    }

    deinit {
        timer?.invalidate()
    }
}
