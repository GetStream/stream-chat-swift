//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button subclass that should be used for creating new channels.
public typealias ChatChannelCreateNewButton = _ChatChannelCreateNewButton<NoExtraData>

/// A Button subclass that should be used for creating new channels.
open class _ChatChannelCreateNewButton<ExtraData: ExtraDataTypes>: Button, UIConfigProvider {
    override public func defaultAppearance() {
        super.defaultAppearance()
        setImage(uiConfig.images.newChat, for: .normal)
    }
}
