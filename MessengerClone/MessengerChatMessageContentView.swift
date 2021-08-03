//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI

struct MessengerChatMessageContentView: ChatMessageContentView.SwiftUIView {
    @EnvironmentObject var appearance: Appearance.ObservableObject
    @EnvironmentObject var components: Components.ObservableObject
    @ObservedObject var dataSource: ChatMessageContentView.ObservedObject<Self>
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    init(dataSource: ChatMessageContentView.ObservedObject<MessengerChatMessageContentView>) {
        self.dataSource = dataSource
    }
    
    var body: some View {
        if let message = dataSource.content {
            VStack {
                Text(dateFormatter.string(from: message.createdAt))
                    .font(Font(appearance.fonts.subheadline as CTFont))
                    .foregroundColor(Color(appearance.colorPalette.subtitleText))
                HStack(alignment: .bottom) {
                    if message.isSentByCurrentUser {
                        Spacer()
                    }
                    if let imageURL = message.author.imageURL {
                        ImageView(url: imageURL)
                            .frame(width: 30, height: 30)
                    }
                    VStack(alignment: message.isSentByCurrentUser ? .trailing : .leading) {
                        if !message.text.isEmpty {
                            Text(message.text)
                                .foregroundColor(
                                    message.isSentByCurrentUser ? Color(appearance.colorPalette.text) : Color.white
                                )
                                .font(Font(appearance.fonts.body as CTFont))
                                .padding([.bottom, .top], 8)
                                .padding([.leading, .trailing], 12)
                                .background(
                                    message.isSentByCurrentUser ? Color(appearance.colorPalette.background2) : Color.blue
                                )
                                .cornerRadius(18)
                        }
                    }
                    if !message.isSentByCurrentUser {
                        Spacer()
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}
