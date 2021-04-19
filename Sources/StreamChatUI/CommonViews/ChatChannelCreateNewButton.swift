//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A Button subclass that should be used for creating new channels.
public typealias ChatChannelCreateNewButton = _ChatChannelCreateNewButton<NoExtraData>

/// A Button subclass that should be used for creating new channels.
open class _ChatChannelCreateNewButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    override open func setUpAppearance() {
        super.setUpAppearance()
        setImage(uiConfig.images.newChat, for: .normal)
    }
}
