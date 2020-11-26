//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class CreateNewChannelButton: Button {
    // MARK: - Overrides
    
    override public func defaultAppearance() {
        defaultIntrinsicContentSize = .init(width: 44, height: 44)
        setImage(UIImage(named: "icn_new_chat", in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
    }

    open var defaultIntrinsicContentSize: CGSize?
    override open var intrinsicContentSize: CGSize {
        defaultIntrinsicContentSize ?? super.intrinsicContentSize
    }
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
