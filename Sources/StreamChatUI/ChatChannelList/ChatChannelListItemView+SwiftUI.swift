//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI
import Combine

@available(iOS 13.0, *)
/// Protocol of `ChatChannelListItemView` wrapper for use in SwiftUI.
public protocol ChatChannelListItemViewSwiftUIView: View {
    init(dataSource: ChatChannelListItemView.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension ChatChannelListItemView {
    /// Data source of `ChatChannelListItemView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content>

    /// `ChatChannelListItemView` represented in SwiftUI.
    public typealias SwiftUIView = ChatChannelListItemViewSwiftUIView

    /// SwiftUI wrapper of `ChatChannelListItemView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `Components`.
    public class SwiftUIWrapper<Content: SwiftUIView>: ChatChannelListItemView, ObservableObject {
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
