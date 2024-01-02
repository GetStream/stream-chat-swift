//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelListLoadingViewCell: _TableViewCell, ThemeProvider {
    /// The `ChatChannelListLoadingViewCellContentView` instance used as content view.
    open private(set) lazy var chatChannelListLoadingViewCellContentView: ChatChannelListLoadingViewCellContentView = components
        .channelListLoadingContentViewCell.init()
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
