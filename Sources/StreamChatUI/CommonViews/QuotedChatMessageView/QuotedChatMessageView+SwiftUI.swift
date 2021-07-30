//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `QuotedChatMessageView` wrapper for use in SwiftUI.
public protocol _QuotedChatMessageViewSwiftUIView: View {
    init(dataSource: _QuotedChatMessageView<ExtraData>.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension _QuotedChatMessageView {
    /// Data source of `QuotedChatMessageView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData

    /// `QuotedChatMessageView` represented in SwiftUI.
    public typealias SwiftUIView = _QuotedChatMessageViewSwiftUIView

    /// SwiftUI wrapper of `QuotedChatMessageView`.
    public class SwiftUIWrapper<Content: SwiftUIView>: _QuotedChatMessageView<ExtraData>, ObservableObject
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
            hostingController?.view.backgroundColor = .clear
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
