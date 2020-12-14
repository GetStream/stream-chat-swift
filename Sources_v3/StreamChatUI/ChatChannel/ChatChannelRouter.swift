//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelRouter<ExtraData: ExtraDataTypes>: ChatRouter<ChatChannelVC<ExtraData>> {
    open func showThreadDetail(for message: _ChatMessage<ExtraData>, within channel: _ChatChannelController<ExtraData>) {}
}
