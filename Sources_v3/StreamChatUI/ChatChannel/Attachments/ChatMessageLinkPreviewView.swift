//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageLinkPreviewView<ExtraData: ExtraDataTypes>: Control, UIConfigProvider {
    public var content: _ChatMessageAttachment<ExtraData>? { didSet { updateContentIfNeeded() } }
}
