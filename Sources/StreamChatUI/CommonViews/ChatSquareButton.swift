//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatSquareButton = _ChatSquareButton<NoExtraData>

internal class _ChatSquareButton<ExtraData: ExtraDataTypes>: _Button, UIConfigProvider {
    // MARK: - Properties
    
    internal var defaultIntrinsicContentSize: CGSize?
    
    // MARK: - Overrides
    
    override internal var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
    
    override internal func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 40, height: 40)
        imageView?.contentMode = .scaleAspectFit
    }
}
