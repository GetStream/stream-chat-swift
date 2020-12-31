//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelRouter<ExtraData: ExtraDataTypes>: ChatRouter<ChatChannelVC<ExtraData>> {
    open func showThreadDetail(for message: _ChatMessage<ExtraData>, within channel: _ChatChannelController<ExtraData>) {
        let controller = ChatThreadVC<ExtraData>()
        controller.channelController = channel
        controller.controller = channel.client.messageController(cid: channel.cid!, messageId: message.id)
        controller.userSuggestionSearchController = channel.client.userSearchController()
        navigationController?.show(controller, sender: self)
    }
}
