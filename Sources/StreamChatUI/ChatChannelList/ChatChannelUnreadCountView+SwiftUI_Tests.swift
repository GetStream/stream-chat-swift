//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatChannelUnreadCountView_SwiftUI_Tests: XCTestCase {
    func test_injectedSwiftUIView() {
        struct CustomUnreadCountView: ChatChannelUnreadCountView.SwiftUIView {
            public typealias ExtraData = NoExtraData

            @ObservedObject var dataSource: ChatChannelUnreadCountView.ObservedObject<Self>

            public init(dataSource: ChatChannelUnreadCountView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            public var body: some View {
                Text(String(dataSource.content.messages))
                    .fontWeight(.bold)
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
            }
        }

        let view = ChatChannelUnreadCountView.SwiftUIWrapper<CustomUnreadCountView>()
        view.content = .mock(messages: 20)
        view.addLayoutConstraints()
        
        AssertSnapshot(view)
    }
}

private extension UIView {
    func addLayoutConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: widthAnchor),
            widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}
