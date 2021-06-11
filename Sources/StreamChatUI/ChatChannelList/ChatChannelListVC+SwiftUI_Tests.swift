//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
class ChatChannelListView_Tests: iOS13TestCase {
    var chatChannelList: SwiftUIViewControllerRepresentable<ChatChannelListVC>!
    var mockedChannelListController: ChatChannelListController_Mock<NoExtraData>!

    var channels: [ChatChannel] = []

    override func setUp() {
        super.setUp()
        mockedChannelListController = ChatChannelListController_Mock.mock()
        chatChannelList = ChatChannelListVC.asView(mockedChannelListController)

        channels = .dummy()
    }

    func test_chatChannelList_isPopulated() {
        mockedChannelListController.simulateInitial(
            channels: channels,
            state: .localDataFetched
        )

        AssertSnapshot(chatChannelList, isEmbeddedInNavigationController: true)
    }

    func test_customNavigationViewValues_arePopulated() {
        struct CustomView: View {
            let mockedChannelListController: ChatChannelListController_Mock<NoExtraData>!
            let channels: [ChatChannel] = .dummy()

            init() {
                mockedChannelListController = ChatChannelListController_Mock.mock()

                mockedChannelListController.simulateInitial(
                    channels: channels,
                    state: .localDataFetched
                )
            }

            var body: some View {
                NavigationView {
                    ChatChannelListVC.asView(mockedChannelListController)
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
