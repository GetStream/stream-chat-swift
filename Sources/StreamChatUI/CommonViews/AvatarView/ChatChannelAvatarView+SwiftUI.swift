//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
/// Protocol of `ChatChannelAvatarView` wrapper for use in SwiftUI.
public protocol ChatChannelAvatarViewSwiftUIView: View {
    init(dataSource: ChatChannelAvatarView.ObservedObject<Self>)
}

@available(iOS 13.0, *)
extension ChatChannelAvatarView {
    /// Data source of `ChatChannelAvatarView` represented as `ObservedObject`.
    public typealias ObservedObject<Content: SwiftUIView> = SwiftUIWrapper<Content>

    /// `ChatChannelAvatarView` represented in SwiftUI.
    public typealias SwiftUIView = ChatChannelAvatarViewSwiftUIView

    /// SwiftUI wrapper of `ChatChannelAvatarView`.
    public class SwiftUIWrapper<Content: SwiftUIView>: ChatChannelAvatarView, ObservableObject {
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
