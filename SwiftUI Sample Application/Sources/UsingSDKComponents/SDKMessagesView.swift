//
// Created by kojiba on 12.08.2021.
//

import SwiftUI
import StreamChat
import StreamChatUI

struct SDKMessagesView: View {

    var chatChannelController: ChatChannelController

    var body: some View {
        VStack {
            Text("Some SwiftUI customer branding")
            ChatMessageListVC.asView(chatChannelController)
            Text("Some SwiftUI customer branding bottom")
        }
    }
}
