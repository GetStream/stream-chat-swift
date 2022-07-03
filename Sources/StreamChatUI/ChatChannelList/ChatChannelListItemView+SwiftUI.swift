//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `ChatChannelListItemView` wrapper for use in SwiftUI.
public protocol ChatChannelListItemViewSwiftUIView: View {
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
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

        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        override public var intrinsicContentSize: CGSize {
            hostingController?.view.intrinsicContentSize ?? super.intrinsicContentSize
        }

        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        override public func setUp() {
            super.setUp()

            let view = Content(dataSource: self)
                .environmentObject(components.asObservableObject)
                .environmentObject(appearance.asObservableObject)
            hostingController = UIHostingController(rootView: view)
            hostingController!.view.backgroundColor = .clear
        }

        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        override public func setUpLayout() {
            hostingController!.view.translatesAutoresizingMaskIntoConstraints = false
            embed(hostingController!.view)
        }

        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        override public func updateContent() {
            objectWillChange.send()
        }
    }
}
