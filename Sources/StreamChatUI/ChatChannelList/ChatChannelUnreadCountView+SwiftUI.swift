//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `_ChatChannelUnreadCountView` wrapper for use in SwiftUI.
public protocol _ChatChannelUnreadCountViewSwiftUIView: View {
    associatedtype ExtraData: ExtraDataTypes
    init(dataSource: _ChatChannelUnreadCountView<ExtraData>.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension _ChatChannelUnreadCountView {
    /// Data source of `_ChatChannelUnreadCountView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData

    /// `_ChatChannelUnreadCountView` represented in SwiftUI.
    public typealias SwiftUIView = _ChatChannelUnreadCountViewSwiftUIView

    /// SwiftUI wrapper of `_ChatChannelUnreadCountView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_UIConfig`.
    public class SwiftUIWrapper<Content: SwiftUIView>: _ChatChannelUnreadCountView<ExtraData>, ObservableObject
        where Content.ExtraData == ExtraData
    {
        var hostingController: UIHostingController<Content>?

        override public var intrinsicContentSize: CGSize {
            hostingController?.view.intrinsicContentSize ?? super.intrinsicContentSize
        }

        override public func setUp() {
            super.setUp()

            let view = Content(dataSource: self)
            hostingController = UIHostingController(rootView: view)
        }

        override public func setUpLayout() {
            embed(hostingController!.view)
        }

        override public func updateContent() {
            objectWillChange.send()
        }
    }
}
