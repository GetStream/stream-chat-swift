//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatChannelRouter = _ChatChannelRouter<NoExtraData>

open class _ChatChannelRouter<ExtraData: ExtraDataTypes>: ChatRouter<_ChatChannelVC<ExtraData>> {
    open func showThreadDetail(for message: _ChatMessage<ExtraData>, within channel: _ChatChannelController<ExtraData>) {
        let controller = ChatThreadVC<ExtraData>()
        controller.channelController = channel
        controller.userSuggestionSearchController = rootViewController.channelController.client.userSearchController()
        controller.controller = channel.client.messageController(cid: channel.cid!, messageId: message.id)
        controller.userSuggestionSearchController = channel.client.userSearchController()
        navigationController?.show(controller, sender: self)
    }
}
