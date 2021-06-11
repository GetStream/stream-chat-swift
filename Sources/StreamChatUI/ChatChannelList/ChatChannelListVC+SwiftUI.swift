//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// A `UIViewControllerRepresentable` subclass which wraps `ChatChannelListVC` and shows list of channels.
public typealias ChatChannelList = SwiftUIViewControllerRepresentable<_ChatChannelListVC<NoExtraData>>

@available(iOS 13.0, *)
public extension SwiftUIViewControllerRepresentable where ViewController: _ChatChannelListVC<NoExtraData> {
    @available(*, deprecated, renamed: "asView")
    init(controller: _ChatChannelListController<NoExtraData>) {
        self.init(
            viewController: ViewController.self,
            content: controller
        )
    }
}

@available(iOS 13.0, *)
extension _ChatChannelListVC {
    /// A SwiftUI View that wraps `_ChatChannelListVC` and shows list of messages.
    @available(*, deprecated, renamed: "asView")
    static func View(controller: _ChatChannelListController<ExtraData>) -> some View {
        asView(controller)
    }
}

extension _ChatChannelListVC: SwiftUIRepresentable {
    public var content: _ChatChannelListController<ExtraData> {
        get {
            controller
        }
        set {
            controller = newValue
        }
    }
}
