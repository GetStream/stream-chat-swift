//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelCreateNewButton<ExtraData: ExtraDataTypes>: Button, UIConfigProvider {
    // MARK: - Overrides
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 44, height: 44)
        setImage(uiConfig.images.newChat, for: .normal)
    }

    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
}
