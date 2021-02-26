//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatSquareButton = _ChatSquareButton<NoExtraData>

open class _ChatSquareButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    // MARK: - Properties
    
    public var defaultIntrinsicContentSize: CGSize?
    
    // MARK: - Overrides
    
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 40, height: 40)
        imageView?.contentMode = .scaleAspectFit
    }
}
