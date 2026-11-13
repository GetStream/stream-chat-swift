//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@main
struct DemoAppTVApp: App {
    private let client = ChatClient(config: ChatClientConfig(apiKey: .init(apiKeyString)))
    @State private var channelList: ChannelList?

    var body: some Scene {
        WindowGroup {
            if let channelList {
                ChannelListView(client: client, channelList: channelList)
            } else {
                LoginView(client: client) { userId in
                    channelList = client.makeChannelList(
                        with: ChannelListQuery(filter: .containMembers(userIds: [userId]))
                    )
                }
            }
        }
    }
}
