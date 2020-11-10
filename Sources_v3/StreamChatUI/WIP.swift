//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public typealias ExtraDataTypes = StreamChat.ExtraDataTypes

public struct UIConfig<ExtraData: ExtraDataTypes> {
    public init() {}
    
    public struct ChannelListUI {
        public var unreadIndicatorView: UnreadIndicatorView<ExtraData>.Type = UnreadIndicatorView<ExtraData>.self
    }

    public var channelList: ChannelListUI = .init()
}
