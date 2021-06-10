//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// A `UIViewControllerRepresentable` subclass which wraps `ChatChannelListVC` and shows list of channels.
public typealias ChatChannelList = _ChatChannelListVC<NoExtraData>.View

@available(iOS 13.0, *)
extension _ChatChannelListVC {
    /// A `UIViewControllerRepresentable` subclass which wraps `ChatChannelListVC` and shows list of channels.
    public struct View: UIViewControllerRepresentable {
        /// The `ChatChannelListController` instance that provides channels data.
        let controller: _ChatChannelListController<ExtraData>

        public init(controller: _ChatChannelListController<ExtraData>) {
            self.controller = controller
        }

        public func makeUIViewController(context: Context) -> _ChatChannelListVC<ExtraData> {
            let vc = _ChatChannelListVC<ExtraData>()
            vc.controller = controller
            
            return vc
        }

        public func updateUIViewController(_ chatChannelListVC: _ChatChannelListVC<ExtraData>, context: Context) {}
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
