//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelCreateNewButton: Button {
    // MARK: - Overrides
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 44, height: 44)
        setImage(UIImage(named: "icn_new_chat", in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
    }

    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
}
