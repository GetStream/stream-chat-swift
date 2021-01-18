//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelDetailSelectionActionCell<ExtraData: ExtraDataTypes>: CollectionViewCell, ChatChannelDetailActionCell,
    UIConfigProvider {
    static var reuseId: String { String(describing: self) }
    
    // MARK: - Properties

    public private(set) lazy var channelDetailActionView: ChatChannelDetailSelectionActionView<ExtraData> =
        uiConfig.channelDetail.channelDetailSelectionActionView.init()

    // MARK: Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelDetailActionView)
    }
}
