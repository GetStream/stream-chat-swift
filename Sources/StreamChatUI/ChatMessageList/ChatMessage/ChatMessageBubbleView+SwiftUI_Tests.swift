//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI

import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatMessageBubbleViewView_SwiftUI_Tests: iOS13TestCase {
    func test_bubble() {
        struct CustomChatMessageBubbleView: ChatMessageBubbleView.SwiftUIView {
            public typealias ExtraData = NoExtraData

            @ObservedObject var dataSource: ChatMessageBubbleView.ObservedObject<Self>
            
            public init(dataSource: ChatMessageBubbleView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            public var body: some View {
                VStack {
                    Text(dataSource.message?.message.text ?? "")
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(width: 100, height: 100)
                }
            }
        }

        let view = ChatMessageBubbleView.SwiftUIWrapper<CustomChatMessageBubbleView>()

        let message: ChatMessage = .mock(
            id: .unique,
            text: "Hello!",
            author: .mock(id: "id")
        )

        view.message = .mock(message: message)
        view.translatesAutoresizingMaskIntoConstraints = false

        AssertSnapshot(view)
    }
}
