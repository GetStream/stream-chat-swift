//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageErrorIndicator = _ChatMessageErrorIndicator<NoExtraData>

open class _ChatMessageErrorIndicator<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    override public func defaultAppearance() {
        super.defaultAppearance()

        setImage(uiConfig.images.messageListErrorIndicator, for: .normal)
        tintColor = uiConfig.colorPalette.alert
    }
}
