//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatChannelRouter = _ChatChannelRouter<NoExtraData>

internal class _ChatChannelRouter<ExtraData: ExtraDataTypes>: ChatRouter<_ChatChannelVC<ExtraData>> {
    internal func showThreadDetail(for message: _ChatMessage<ExtraData>, within channel: _ChatChannelController<ExtraData>) {
        let controller = _ChatThreadVC<ExtraData>()
        controller.channelController = channel
        controller.controller = channel.client.messageController(cid: channel.cid!, messageId: message.id)
        navigationController?.show(controller, sender: self)
    }
}
