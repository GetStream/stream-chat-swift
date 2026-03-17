//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

struct ChatChannelListRepresentable: UIViewControllerRepresentable {
    let controller: ChatChannelListController

    func makeUIViewController(context: Context) -> ChatChannelListVC {
        let vc = ChatChannelListVC()
        vc.controller = controller
        return vc
    }

    func updateUIViewController(_ uiViewController: ChatChannelListVC, context: Context) {}
}

struct MessengerChatChannelList: View {
    var body: some View {
        NavigationView {
            ChatChannelListRepresentable(
                controller: ChatClient
                    .shared
                    .channelListController(
                        query: ChannelListQuery(
                            filter: .containMembers(
                                userIds: [ChatClient.shared.currentUserId!]
                            )
                        )
                    )
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Chats")
        }
    }
}
