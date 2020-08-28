//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import SwiftUI

@available(iOS 13, *)
struct ChannelListView: View {
    // TODO: It's safer to use `@StateObject` here because `@ObservedObject` can sometimes release the
    // reference and this will crash.
    @ObservedObject var channelList: ChannelListController.ObservableObject

    var body: some View {
        VStack {
            List(channelList.channels, id: \.self) { channel in
                Text(channel.extraData.name ?? "missing channel name")
            }
        }
        .navigationBarTitle("Channels")
    }
}
