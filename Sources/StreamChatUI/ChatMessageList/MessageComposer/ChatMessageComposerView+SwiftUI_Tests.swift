//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatMessageComposerView_SwiftUI_Tests: iOS13TestCase {
    func test_injectedSwiftUIView() {
        struct CustomChatMessageComposerView: ChatMessageComposerView.SwiftUIView {
            public typealias ExtraData = NoExtraData

            @ObservedObject var dataSource: ChatMessageComposerView.ObservedObject<Self>
            @State var typedMessage: String = ""
            
            public init(dataSource: ChatMessageComposerView.ObservedObject<Self>) {
                self.dataSource = dataSource
            }

            public var body: some View {
                HStack {
                    TextField("Type a message..", text: $typedMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: CGFloat(30))
                    Button("Send") {}
                }
                .frame(minHeight: CGFloat(50)).padding()
            }
        }

        let view = ChatMessageComposerView.SwiftUIWrapper<CustomChatMessageComposerView>()
        view.translatesAutoresizingMaskIntoConstraints = false

        AssertSnapshot(view)
    }
}
