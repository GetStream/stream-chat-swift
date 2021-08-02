//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// A `UIViewControllerRepresentable` subclass which wraps `ChatChannelListVC` and shows list of channels.
public typealias ChatChannelList = SwiftUIViewControllerRepresentable<ChatChannelListVC>

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
public extension SwiftUIViewControllerRepresentable where ViewController: ChatChannelListVC {
    @available(*, deprecated, renamed: "asView")
    init(controller: ChatChannelListController) {
        self.init(
            viewController: ViewController.self,
            content: controller
        )
    }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
extension ChatChannelListVC {
    /// A SwiftUI View that wraps `_ChatChannelListVC` and shows list of messages.
    @available(*, deprecated, renamed: "asView")
    static func View(controller: ChatChannelListController) -> some View {
        asView(controller)
    }
}

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
