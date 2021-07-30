//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `_ChatChannelListItemView` wrapper for use in SwiftUI.
public protocol _ChatChannelListItemViewSwiftUIView: View {
    init(dataSource: _ChatChannelListItemView<ExtraData>.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension ChatChannelListItemView {
    /// Data source of `_ChatChannelListItemView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData

    /// `_ChatChannelListItemView` represented in SwiftUI.
    public typealias SwiftUIView = _ChatChannelListItemViewSwiftUIView

    /// SwiftUI wrapper of `_ChatChannelListItemView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_Components`.
    public class SwiftUIWrapper<Content: SwiftUIView>: _ChatChannelListItemView<ExtraData>, ObservableObject
        where Content.ExtraData == ExtraData
    {
        var hostingController: UIViewController?

        override public var intrinsicContentSize: CGSize {
            hostingController?.view.intrinsicContentSize ?? super.intrinsicContentSize
        }

        override public func setUp() {
            super.setUp()

            let view = Content(dataSource: self)
                .environmentObject(components.asObservableObject)
                .environmentObject(appearance.asObservableObject)
            hostingController = UIHostingController(rootView: view)
            hostingController!.view.backgroundColor = .clear
        }

        override public func setUpLayout() {
            hostingController!.view.translatesAutoresizingMaskIntoConstraints = false
            embed(hostingController!.view)
        }

        override public func updateContent() {
            objectWillChange.send()
        }
    }
}
