//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOSApplicationExtension, unavailable)
extension ChatChannelVC: SwiftUIRepresentable {
    public var content: ChatChannelController {
        get {
            channelController
        }
        set {
            channelController = newValue
        }
    }
}
