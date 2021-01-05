//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatSquareButton<ExtraData: ExtraDataTypes>: Button, UIConfigProvider {
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
