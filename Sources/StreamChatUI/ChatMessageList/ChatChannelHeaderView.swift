//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view that displays channel information on the message list header
public typealias ChatChannelHeaderView = _ChatChannelHeaderView<NoExtraData>

/// The view that displays channel information on the message list header
open class _ChatChannelHeaderView<ExtraData: ExtraDataTypes>:
    _View,
    ThemeProvider,
    _ChatChannelControllerDelegate {
    /// Controller for observing data changes within the channel.
    open var channelController: _ChatChannelController<ExtraData>? {
        didSet {
            channelController?.setDelegate(self)
        }
    }

    /// The user id of the current logged in user.
    open var currentUserId: UserId? {
        channelController?.client.currentUserId
    }

    /// Timer used to update the online status of member in the channel.
    open var timer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }

    /// The amount of time it updates the online status of the members.
    /// By default it is 60 seconds.
    open var statusUpdateInterval: TimeInterval { 60 }

    /// A view that displays a title label and subtitle in a container stack view.
    open private(set) lazy var titleContainerView: TitleContainerView = components
        .titleContainerView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()

        makeTimer()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(titleContainerView)
    }

    override open func updateContent() {
        super.updateContent()

        titleContainerView.content = (titleText, subtitleText)
    }

    /// The title text used to render the title label. By default it is the channel name.
    open var titleText: String? {
        guard let channel = channelController?.channel else { return nil }
        return components.channelNamer(channel, currentUserId)
    }

    /// The subtitle text used in the subtitle label. By default it shows member online status.
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

    /// Create the timer to repeatedly update the online status of the members.
    open func makeTimer() {
        // Only create the timer if is not created yet and if the interval is not zero.
        guard timer == nil, statusUpdateInterval > 0 else {
            return
        }

        timer = Timer.scheduledTimer(
            withTimeInterval: statusUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateContentIfNeeded()
        }
    }

    // MARK: - ChatChannelControllerDelegate Implementation

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        switch channel {
        case .update, .create:
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
