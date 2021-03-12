//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `_ChatMessageComposerView` wrapper for use in SwiftUI.
public protocol _ChatMessageComposerViewSwiftUIView: View {
    associatedtype ExtraData: ExtraDataTypes
    init(dataSource: _ChatMessageComposerView<ExtraData>.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension _ChatMessageComposerView {
    /// Data source of `_ChatMessageComposerView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content> where Content.ExtraData == ExtraData

    /// `_ChatChannelListItemView` represented in SwiftUI.
    public typealias SwiftUIView = _ChatMessageComposerViewSwiftUIView

    /// SwiftUI wrapper of `_ChatMessageComposerView`.
    /// Servers to wrap custom SwiftUI view as a UIKit view so it can be easily injected into `_UIConfig`.
    public class SwiftUIWrapper<Content: SwiftUIView>: _ChatMessageComposerView<ExtraData>, ObservableObject
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
