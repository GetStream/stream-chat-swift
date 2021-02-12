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
        defaultIntrinsicContentSize = .init(width: 44, height: 44)
        setImage(uiConfig.images.newChat, for: .normal)
    }

    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
}
