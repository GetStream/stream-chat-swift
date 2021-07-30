//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `_ChatMessageContentView` wrapper for use in SwiftUI.
public protocol ChatMessageContentViewSwiftUIView: View {
    init(dataSource: ChatMessageContentView.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension ChatMessageContentView {
    /// Data source of `_ChatMessageContentView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content>

    /// `_ChatMessageContentView` represented in SwiftUI.
    public typealias SwiftUIView = ChatMessageContentViewSwiftUIView

    /// SwiftUI wrapper of `_ChatMessageContentView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_Components`.
    public class SwiftUIWrapper<Content: SwiftUIView>: ChatMessageContentView, ObservableObject {
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
