//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// MARK: - Main listener

final class ChatChannelNavigationBarListener<ExtraData: ExtraDataTypes> {
    typealias NavbarData = (title: String?, subtitle: String?)

    let channelController: _ChatChannelController<ExtraData>
    let memberController: _ChatChannelMemberController<ExtraData>?
    let namer: ChatChannelNamer<ExtraData>
    let onDataChange: (NavbarData) -> Void
    
    var timer: Timer?
    let df: DateComponentsFormatter = {
        let df = DateComponentsFormatter()
        df.allowedUnits = [.minute]
        df.unitsStyle = .full
        return df
    }()
    
    var title: String? {
        channelController.channel.flatMap { namer($0, channelController.client.currentUserId) }
    }
    
    var subtitle: String? {
        if channelController.isChannelDirect {
            guard let member = memberController?.member else { return nil }
            
            if member.isOnline {
                // ReallyNotATODO: Missing API GroupA.m1
                // need to specify how long user have been online
                return "Online"
            } else if let minutes = member.lastActiveAt.flatMap({ df.string(from: $0, to: Date()) }) {
                return "Seen \(minutes) ago"
            } else {
                return "Offline"
            }
        } else {
            return channelController.channel.map { "\($0.memberCount) members, \($0.watcherCount) online" }
        }
    }

    init(client: _ChatClient<ExtraData>, channel: ChannelId, namer: @escaping ChatChannelNamer<ExtraData>, onDataChange: @escaping (NavbarData) -> Void) {
        self.namer = namer
        self.onDataChange = onDataChange
        self.channelController = client.channelController(for: channel)
        
        if channelController.isChannelDirect {
            memberController = channelController
                .channel?
                .cachedMembers
                .first { $0.id != client.currentUserId }
                .map { client.memberController(userId: $0.id, in: channel) }

            timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.fireNewNavbarData()
            }
        } else {
            memberController = nil
        }
                
        channelController.setDelegate(self)
        memberController?.setDelegate(self)
        memberController?.synchronize()

        fireNewNavbarData()
    }

    func fireNewNavbarData() {
        let content = (title, subtitle)
        onDataChange(content)
    }
}

extension ChatChannelNavigationBarListener: _ChatChannelControllerDelegate {
    func channelController(
        _ channelController: _ChatChannelController<ExtraData>,
        didUpdateChannel channel: EntityChange<_ChatChannel<ExtraData>>
    ) {
        fireNewNavbarData()
    }
}

extension ChatChannelNavigationBarListener: _ChatChannelMemberControllerDelegate {
    func memberController(
        _ controller: _ChatChannelMemberController<ExtraData>,
        didUpdateMember change: EntityChange<_ChatChannelMember<ExtraData.User>>
    ) {
        fireNewNavbarData()
    }
}
