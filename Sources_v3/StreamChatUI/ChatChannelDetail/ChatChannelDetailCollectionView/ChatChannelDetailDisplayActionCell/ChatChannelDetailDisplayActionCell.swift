//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailDisplayActionCell<ExtraData: ExtraDataTypes>: CollectionViewCell, ChatChannelDetailActionCell,
    UIConfigProvider {
    static var reuseId: String { String(describing: self) }
    
    // MARK: - Properties

    public private(set) lazy var channelDetailActionView: ChatChannelDetailDisplayActionView<ExtraData> =
        uiConfig.channelDetail.channelDetailDisplayActionView.init()

    // MARK: Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelDetailActionView)
    }
}
