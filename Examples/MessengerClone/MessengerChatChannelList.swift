//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI

struct MessengerChatChannelList: View {
    var body: some View {
        NavigationView {
            ChatChannelListVC.asView(
                ChatClient
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
