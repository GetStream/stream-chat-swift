//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatChannelUnreadCountView_SwiftUI_Tests: XCTestCase {
    func test_injectedSwiftUIView() {
        struct CustomUnreadCountView: ChatChannelUnreadCountView.SwiftUIView {
            @ObservedObject var dataSource: ChatChannelUnreadCountView.ObservedObject<Self>

            public init(dataSource: ChatChannelUnreadCountView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            public var body: some View {
                Text(String(dataSource.content.messages))
                    .fontWeight(.bold)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
            }
        }

        let view = ChatChannelUnreadCountView.SwiftUIWrapper<CustomUnreadCountView>()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.content = .mock(messages: 20)
        AssertSnapshot(view)
    }
}
