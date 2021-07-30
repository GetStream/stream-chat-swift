//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

extension _ChatMessageListVC: SwiftUIRepresentable {
    public var content: ChatChannelController {
        get {
            channelController
        }
        set {
            channelController = newValue
        }
    }
}
