//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI

struct MessengerChatChannelListItem: ChatChannelListItemView.SwiftUIView {
    @EnvironmentObject var components: Components.ObservableObject
    @ObservedObject var dataSource: ChatChannelListItemView.ObservedObject<Self>
    init(dataSource: ChatChannelListItemView.ObservedObject<MessengerChatChannelListItem>) {
        self.dataSource = dataSource
    }
    
    var body: some View {
        HStack {
            components
                .channelAvatarView
                .asView((dataSource.content?.channel, dataSource.content?.currentUserId))
                .frame(width: 50, height: 50)
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(dataSource.titleText ?? "")
                    .font(.system(.body))
                Text(
                    (dataSource.subtitleText ?? "")
                        + " • "
                        + (dataSource.timestampText ?? "")
                )
                .font(.system(.footnote))
                .foregroundColor(Color.gray)
            }
            
            Spacer()
        }
        .padding()
    }

    private func imageURL() -> URL? {
        guard let channel = dataSource.content?.channel else { return nil }

        if let avatarURL = channel.imageURL {
            return avatarURL
        }

        let firstOtherMember = channel
            .lastActiveMembers
            .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
            .first { $0.id != channel.membership?.id }

        return firstOtherMember?.imageURL
    }
}
