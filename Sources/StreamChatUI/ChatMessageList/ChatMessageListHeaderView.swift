//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

typealias ChatMessageListHeaderView = _ChatMessageListHeaderView<NoExtraData>

open class _ChatMessageListHeaderView<ExtraData: ExtraDataTypes>: _View, ThemeProvider, _ChatChannelControllerDelegate {
    /// Content of the view
    public struct Content {
        var channel: _ChatChannel<ExtraData>?
        var currentUserId: UserId?
    }

    /// Content of the view
    open var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// Timer used to update the online status of member in the chat channel
    open var timer: Timer?

    open private(set) lazy var headerTitleView: HeaderTitleView = components
        .headerTitleView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        embed(headerTitleView)
    }

    override open func updateContent() {
        super.updateContent()

        headerTitleView.content = (titleText, subtitleText)

        /// If the channel is direct between two people, call update content
        /// repeatedly every minute to update the online status of the members.
        if timer == nil, content?.channel?.isDirectMessageChannel == true {
            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.updateContent()
            }
        } else {
            timer = nil
        }
    }

    open var titleText: String? {
        guard let channel = content?.channel else { return nil }
        return components.channelNamer(channel, content?.currentUserId)
    }

    open var subtitleText: String? {
        let channel = content?.channel
        if channel?.isDirectMessageChannel == true {
            guard let member = channel?.lastActiveMembers.first else { return nil }

            if member.isOnline {
                // ReallyNotATODO: Missing API GroupA.m1
                // need to specify how long user have been online
                return L10n.Message.Title.online
            } else if let minutes = member.lastActiveAt
                .flatMap({ DateComponentsFormatter.minutes.string(from: $0, to: Date()) }) {
                return L10n.Message.Title.seeMinutesAgo(minutes)
            } else {
                return L10n.Message.Title.offline
            }
        }

        return channel.map { L10n.Message.Title.group($0.memberCount, $0.watcherCount) }
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        switch channel {
        case let .update(item):
            content?.channel = item
        default:
            break
        }
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didChangeTypingUsers typingUsers: Set<_ChatUser<ExtraData.User>>
    ) {
        // No-op
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didReceiveMemberEvent: MemberEvent
    ) {
        // No-op
    }

    open func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateMessages changes: [ListChange<_ChatMessage<ExtraData>>]
    ) {
        // No-op
    }

    deinit {
        timer?.invalidate()
    }
}
