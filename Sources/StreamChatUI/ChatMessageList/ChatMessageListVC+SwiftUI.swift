//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// A SwiftUI View that wraps `ChatMessageListVC` and shows list of messages.
public typealias ChatMessageListView = _ChatMessageListVC<NoExtraData>.View

@available(iOS 13.0, *)
extension _ChatMessageListVC {
    /// A SwiftUI View that wraps `ChatMessageListVC` and shows list of messages.
    public struct View: UIViewControllerRepresentable {
        /// The `_ChatChannelController` instance that provides channel data.
        let controller: _ChatChannelController<ExtraData>

        public init(controller: _ChatChannelController<ExtraData>) {
            self.controller = controller
        }

        public func makeUIViewController(context: Context) -> _ChatMessageListVC<ExtraData> {
            let vc = _ChatMessageListVC<ExtraData>()
            vc.channelController = controller
            return vc
        }

        public func updateUIViewController(_ chatChannelListVC: _ChatMessageListVC<ExtraData>, context: Context) {}
    }
}
