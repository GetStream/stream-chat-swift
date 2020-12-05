//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatSquareButton<ExtraData: UIExtraDataTypes>: Button, UIConfigProvider {
    // MARK: - Properties
    
    public var defaultIntrinsicContentSize: CGSize?
    
    // MARK: - Overrides
    
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
    
    override open func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 40, height: 40)
        imageView?.contentMode = .scaleAspectFit
    }
}
