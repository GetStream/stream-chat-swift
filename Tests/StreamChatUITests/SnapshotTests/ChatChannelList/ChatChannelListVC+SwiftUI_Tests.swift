//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13.0, *)
final class ChatChannelListView_Tests: iOS13TestCase {
    var chatChannelList: SwiftUIViewControllerRepresentable<ChatChannelListVC>!
    var mockedChannelListController: ChatChannelListController_Mock!

    var channels: [ChatChannel] = []

    override func setUp() {
        super.setUp()
        
        // TODO: We have to replace default as the components are not injected in SwiftUI views.
        Components.default = .mock
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
            let mockedChannelListController: ChatChannelListController_Mock!
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
                        ).environmentObject(Components.mock.asObservableObject)
                }
            }
        }

        let customView = CustomView()
        AssertSnapshot(customView)
    }
}
