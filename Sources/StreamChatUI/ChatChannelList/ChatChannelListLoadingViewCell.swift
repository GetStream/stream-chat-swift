//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelListLoadingViewCell: _TableViewCell, ThemeProvider, SkeletonLoadable {
    /// The `ChatChannelListLoadingViewCellContentView` instance used as content view.
    open private(set) lazy var chatChannelListLoadingViewCellContentView: ChatChannelListLoadingViewCellContentView = .init()
        .withoutAutoresizingMaskConstraints
    
    override open func setUp() {
        super.setUp()
        isUserInteractionEnabled = false
    }

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.addSubview(chatChannelListLoadingViewCellContentView)
        chatChannelListLoadingViewCellContentView.pin(to: contentView)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        chatChannelListLoadingViewCellContentView.layoutSubviews()
    }
}
