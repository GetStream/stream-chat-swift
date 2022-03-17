//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
final class ChatChannelView_Tests: iOS13TestCase {
    var chatChannel: SwiftUIViewControllerRepresentable<ChatChannelVC>!
    var mockedChannelController: ChatChannelController_Mock!

    override func setUp() {
        super.setUp()
        mockedChannelController = ChatChannelController_Mock.mock()
        chatChannel = ChatChannelVC.asView(mockedChannelController)
    }

    func test_chatChannel_isPopulated() {
        mockedChannelController.simulateInitial(
            channel: .mock(cid: .unique),
            messages: [
                .mock(id: .unique, cid: .unique, text: "One", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Two", author: .mock(id: .unique)),
                .mock(id: .unique, cid: .unique, text: "Three", author: .mock(id: .unique))
            ],
            state: .localDataFetched
        )

        AssertSnapshot(
            chatChannel,
            isEmbeddedInNavigationController: true,
            variants: [.defaultLight]
        )
    }

    func test_customNavigationViewValues_arePopulated() {
        struct CustomView: View {
            let mockedChannelController = ChatChannelController_Mock.mock()
            let mockedUserSearchController = ChatUserSearchController_Mock.mock()

            init() {
                mockedChannelController.simulateInitial(
                    channel: .mock(cid: .unique),
                    messages: [
                        .mock(id: .unique, cid: .unique, text: "One", author: .mock(id: .unique)),
                        .mock(id: .unique, cid: .unique, text: "Two", author: .mock(id: .unique))
                    ],
                    state: .localDataFetched
                )
            }

            var body: some View {
                NavigationView {
                    ChatChannelVC.asView(mockedChannelController)
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
