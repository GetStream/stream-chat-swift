//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI
import Combine

@available(iOS 13.0, *)
/// Protocol of `ChatChannelUnreadCountView` wrapper for use in SwiftUI.
public protocol ChatChannelUnreadCountViewSwiftUIView: View {
    init(dataSource: ChatChannelUnreadCountView.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension ChatChannelUnreadCountView {
    /// Data source of `ChatChannelUnreadCountView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content>

    /// `ChatChannelUnreadCountView` represented in SwiftUI.
    public typealias SwiftUIView = ChatChannelUnreadCountViewSwiftUIView

    /// SwiftUI wrapper of `ChatChannelUnreadCountView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `Components`.
    public class SwiftUIWrapper<Content: SwiftUIView>: ChatChannelUnreadCountView, ObservableObject {
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
