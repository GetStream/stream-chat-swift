//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

public extension _ChatClient {
    func channelListVC(query: _ChannelListQuery<ExtraData.Channel>? = nil) -> _ChatChannelListVC<ExtraData> {
        let query = query ?? .init(filter: .containMembers(userIds: [currentUserId].compactMap { $0 }))
        let channelListVC = _ChatChannelListVC<ExtraData>()
        let controller = channelListController(query: query)
        channelListVC.controller = controller
        return channelListVC
    }
    
    func channelVC(type: ChannelType, id: String) -> _ChatChannelVC<ExtraData> {
        let channelVC = _ChatChannelVC<ExtraData>()
        let channelId = ChannelId(type: type, id: id)
        let controller = channelController(for: channelId)
        channelVC.channelController = controller
        return channelVC
    }
}
