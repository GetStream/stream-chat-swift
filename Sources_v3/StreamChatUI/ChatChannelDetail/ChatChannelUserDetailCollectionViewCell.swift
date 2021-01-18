//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelUserDetailCollectionViewCell<ExtraData: ExtraDataTypes>: CollectionViewCell, UIConfigProvider {
    // MARK: - Properties

    public private(set) lazy var channelDetailItemView: ChatChannelUserDetailItemView<ExtraData> =
        uiConfig.channelDetail.channelDetailItemView.init()

    // MARK: Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelDetailItemView)
    }
}
