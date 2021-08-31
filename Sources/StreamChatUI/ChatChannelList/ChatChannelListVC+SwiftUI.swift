//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// A `UIViewControllerRepresentable` subclass which wraps `ChatChannelListVC` and shows list of channels.
public typealias ChatChannelList = SwiftUIViewControllerRepresentable<ChatChannelListVC>

@available(iOSApplicationExtension, unavailable)
extension ChatChannelListVC: SwiftUIRepresentable {
    public var content: ChatChannelListController {
        get {
            controller
        }
        set {
            controller = newValue
        }
    }
}
