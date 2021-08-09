//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOSApplicationExtension, unavailable)
extension ChatChannelVC: SwiftUIRepresentable {
    public var content: (
        channelController: ChatChannelController,
        userSearchController: ChatUserSearchController
    ) {
        get {
            (channelController, userSuggestionSearchController)
        }
        set {
            channelController = newValue.channelController
            userSuggestionSearchController = newValue.userSearchController
        }
    }
}
