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
    static let shared = User()

    let id = "luke_skywalker"
    let name = "Luke Skywalker"
    let avatarURL = URL(string: "https://vignette.wikia.nocookie.net/starwars/images/2/20/LukeTLJ.jpg")!
    let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
    let apiKeyString = "8br4watad788"
}

extension ChatClient {
    static let shared: ChatClient = {
        let user = User.shared
        let config = ChatClientConfig(apiKey: APIKey(user.apiKeyString))

        // dont looks like a proper injections
        let chatClient = ChatClient(config: config)
        chatClient.connectUser(userInfo: UserInfo(id: user.id),
            token: try! Token(rawValue: user.token))
        return chatClient
    }()
}

extension ChatChannelController {
    static let empty: ChatChannelController = ChatClient.shared.channelController(for: ChannelId(type: .messaging, id: "12345"))
}

class AppModel: ObservableObject {
    static let shared = AppModel()

    let user = User.shared
    let chatClient: ChatClient = .shared

    @Published var isNavigatingMessagesList = false
    @Published var openingChatChannelController: ChatChannelController = .empty

    var channelListController: ChatChannelListController {
        chatClient.channelListController(query: ChannelListQuery(filter: .containMembers(userIds: [user.id])))
    }

    init() {
        CustomRouter.showMessageListClosure = { [weak self] chatId in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.openingChatChannelController = strongSelf.chatClient.channelController(for: chatId)
            strongSelf.isNavigatingMessagesList.toggle()
        }

        var components = Components()
        components.channelListRouter = CustomRouter.self
        Components.default = components
    }
}

@main
struct SwiftUISampleApp: App {

    @ObservedObject var model = AppModel.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                VStack(spacing: .zero) {
                    SDKChannelsView(channelListController: model.channelListController)

                    NavigationLink(destination: SDKMessagesView(chatChannelController: model.openingChatChannelController),
                        isActive: $model.isNavigatingMessagesList) {
                        EmptyView()
                    }
                }
                    .navigationBarTitle("SDK Chat List")
            }
        }
    }
    
    init() {
        // init here
    }
}
