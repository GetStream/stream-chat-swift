//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `_ChatChannelUnreadCountView` wrapper for use in SwiftUI.
public protocol _ChatChannelUnreadCountViewSwiftUIView: View {
    init(dataSource: _ChatChannelUnreadCountView<ExtraData>.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension ChatChannelUnreadCountView {
    /// Data source of `_ChatChannelUnreadCountView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData

    /// `_ChatChannelUnreadCountView` represented in SwiftUI.
    public typealias SwiftUIView = _ChatChannelUnreadCountViewSwiftUIView

    /// SwiftUI wrapper of `_ChatChannelUnreadCountView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_Components`.
    public class SwiftUIWrapper<Content: SwiftUIView>: _ChatChannelUnreadCountView<ExtraData>, ObservableObject
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
