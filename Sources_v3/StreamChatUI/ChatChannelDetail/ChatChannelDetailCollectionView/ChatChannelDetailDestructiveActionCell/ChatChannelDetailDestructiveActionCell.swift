//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailDestructiveActionCell<ExtraData: ExtraDataTypes>: CollectionViewCell, ChatChannelDetailActionCell,
    UIConfigProvider {
    static var reuseId: String { String(describing: self) }
    
    // MARK: - Properties

    public private(set) lazy var channelDetailActionView: ChatChannelDetailDestructiveActionView<ExtraData> =
        uiConfig.channelDetail.channelDetailDestructiveActionView.init()

    // MARK: Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelDetailActionView)
    }
}
