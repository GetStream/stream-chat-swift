//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Main listener

class ChatChannelNavigationBarListener<ExtraData: ExtraDataTypes> {
    typealias NavbarData = (title: String?, subtitle: String?)

    let channelController: _ChatChannelController<ExtraData>
    let namer: ChatChannelNamer<ExtraData>
    var onDataChange: (NavbarData) -> Void = { _ in }

    static func make(
        for channel: ChannelId,
        in client: _ChatClient<ExtraData>,
        using namer: @escaping ChatChannelNamer<ExtraData>
    ) -> ChatChannelNavigationBarListener {
        /// if we in channel room, channel will be here, but it always safe to fallback to group chat
        let isDirect = client.channelController(for: channel).channel?.isDirectMessageChannel ?? false
        return isDirect
            ? DirectChatChannelNavigationBarListener(client: client, channel: channel, namer: namer)
            : GroupChatChannelNavigationBarListener(client: client, channel: channel, namer: namer)
    }

    fileprivate init(client: _ChatClient<ExtraData>, channel: ChannelId, namer: @escaping ChatChannelNamer<ExtraData>) {
        self.namer = namer
        
        channelController = client.channelController(for: channel)
        channelController.setDelegate(self)

        fireNewNavbarData()
    }

    func fireNewNavbarData() {
        let data = makeNavbarData()
        onDataChange(data)
    }

    func makeNavbarData() -> NavbarData {
        (nil, nil)
    }
}

extension ChatChannelNavigationBarListener: _ChatChannelControllerDelegate {
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) { fireNewNavbarData() }
}

// MARK: - Group child

private class GroupChatChannelNavigationBarListener<ExtraData: ExtraDataTypes>: ChatChannelNavigationBarListener<ExtraData> {
    override func makeNavbarData() -> NavbarData {
        guard let channel = channelController.channel else { return (nil, nil) }
        let title = namer(channel, channelController.client.currentUserId)
        let subtitle = "\(channel.memberCount) members, \(channel.watcherCount) online"
        return (title, subtitle)
    }
}

// MARK: - Direct child

private class DirectChatChannelNavigationBarListener<ExtraData: ExtraDataTypes>: ChatChannelNavigationBarListener<ExtraData> {
    let memberController: _ChatChannelMemberController<ExtraData>?
    let df: DateComponentsFormatter = {
        let df = DateComponentsFormatter()
        df.allowedUnits = [.minute]
        df.unitsStyle = .full
        return df
    }()

    private var timer: Timer!

    override init(client: _ChatClient<ExtraData>, channel: ChannelId, namer: @escaping ChatChannelNamer<ExtraData>) {
        memberController = client.channelController(for: channel).channel?.cachedMembers
            .first { $0.id != client.currentUserId }
            .map { client.memberController(userId: $0.id, in: channel) }
        super.init(client: client, channel: channel, namer: namer)

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.fireNewNavbarData()
        }

        memberController?.setDelegate(self)
        memberController?.synchronize()
    }

    override func makeNavbarData() -> NavbarData {
        guard let channel = channelController.channel else { return (nil, nil) }
        let title = namer(channel, channelController.client.currentUserId)
        guard let member = memberController?.member else { return (title, nil) }
        let subtitle: String
        if member.isOnline {
            // ReallyNotATODO: Missing API GroupA.m1
            // need to specify how long user have been online
            subtitle = "Online"
        } else {
            if let lastActive = member.lastActiveAt, let minutes = df.string(from: lastActive, to: Date()) {
                subtitle = "Seen \(minutes) ago"
            } else {
                subtitle = "Offline"
            }
        }
        return (title, subtitle)
    }
}

extension DirectChatChannelNavigationBarListener: _ChatChannelMemberControllerDelegate {
    func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) { fireNewNavbarData() }
}
