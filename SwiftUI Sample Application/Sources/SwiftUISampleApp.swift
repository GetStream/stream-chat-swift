//
//  SwiftUISampleApp.swift
//  SwiftUISample
//
//  Created by kojiba on 10.08.2021.
//

import SwiftUI
import StreamChat
import StreamChatUI

// TODO: refactor
struct User {
    let id = "luke_skywalker"
    let name = "Luke Skywalker"
    let avatarURL = URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!
    let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
    let apiKeyString = "8br4watad788"
}

class AppModel: ObservableObject {
    static let shared = AppModel()

    let user = User()
    let chatClient: ChatClient

    init() {
        let config = ChatClientConfig(apiKey: APIKey(user.apiKeyString))
        chatClient = ChatClient(config: config)
        chatClient.connectUser(userInfo: UserInfo(id: user.id),
            token: try! Token(rawValue: user.token))
    }
}

@main
struct SwiftUISampleApp: App {

    @ObservedObject var model = AppModel.shared
    
    var body: some Scene {
        WindowGroup {
            SDKChannelsView(channelListController:
                model
                    .chatClient
                    .channelListController(query:
                        ChannelListQuery(filter: .containMembers(userIds: [model.user.id]))
                    )
            )

//            ChannelListView(channelListController:
//                model
//                    .chatClient
//                    .channelListController(query:
//                        ChannelListQuery(filter: .containMembers(userIds: [model.user.id]))
//                    )
//            )
        }
    }
    
    init() {
        // init here
    }
}
