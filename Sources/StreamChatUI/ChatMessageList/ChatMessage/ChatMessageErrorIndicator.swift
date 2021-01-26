//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageErrorIndicator = _ChatMessageErrorIndicator<NoExtraData>

open class _ChatMessageErrorIndicator<ExtraData: ExtraDataTypes>: Button, UIConfigProvider {
    override public func defaultAppearance() {
        super.defaultAppearance()

        setImage(UIImage(named: "error_indicator", in: .streamChatUI)!, for: .normal)
        tintColor = uiConfig.colorPalette.outgoingMessageErrorIndicatorTint
    }
}
