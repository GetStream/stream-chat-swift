//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatMessageListView_Tests: iOS13TestCase {
    var chatMessageList: ChatMessageListView!
    var mockedChannelController: ChatChannelController_Mock<NoExtraData>!

    override func setUp() {
        super.setUp()
        mockedChannelController = ChatChannelController_Mock.mock()
        chatMessageList = ChatMessageListVC.View(controller: mockedChannelController)
    }

    func test_chatMessageList_isPopulated() {
        mockedChannelController.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, text: "One", author: .mock(id: .unique)),
                .mock(id: .unique, text: "Two", author: .mock(id: .unique)),
                .mock(id: .unique, text: "Three", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )

        AssertSnapshot(
            chatMessageList,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_customNavigationViewValues_arePopulated() {
        struct CustomView: View {
            let mockedChannelController = ChatChannelController_Mock<NoExtraData>.mock()

            init() {
                mockedChannelController.simulateInitial(
                    channel: .mock(cid: .unique),
                    messages: [
                        .mock(id: .unique, text: "One", author: .mock(id: .unique)),
                        .mock(id: .unique, text: "Two", author: .mock(id: .unique))
                    ],
                    state: .localDataFetched
                )
            }

            var body: some View {
                NavigationView {
                    ChatMessageListVC.View(controller: mockedChannelController)
                        .navigationBarTitle("Custom title", displayMode: .inline)
                        .navigationBarItems(
                            leading:
                            Button("Tap me!") {}
                        )
                }
            }
        }

        let customView = CustomView()
        AssertSnapshot(customView)
    }
}
