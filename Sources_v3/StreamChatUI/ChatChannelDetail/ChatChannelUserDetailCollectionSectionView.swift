//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelUserDetailCollectionSectionView<ExtraData: ExtraDataTypes>: UICollectionReusableView, UIConfigProvider {
    class var reuseId: String { String(describing: self) }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = uiConfig.colorPalette.channelDetailSectionHeaderBgColor
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
