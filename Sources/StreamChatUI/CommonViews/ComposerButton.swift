//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ComposerButton = _ComposerButton<NoExtraData>

open class _ComposerButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    public var defaultIntrinsicContentSize: CGSize?

    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 40, height: 40)
        imageView?.contentMode = .scaleAspectFit
    }
}
