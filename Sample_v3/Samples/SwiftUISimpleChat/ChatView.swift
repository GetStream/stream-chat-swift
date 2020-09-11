//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import SwiftUI

@available(iOS 13, *)
struct ChatView: View {
    /// SwiftUI expects view initialization to be cheap, so we hold the a `ChannelController` builder to be called in `onAppear`.
    let channelBuilder: () -> ChannelController.ObservableObject
    /// The `ChannelController` used to interact with this channel. Will be set in `onAppear`.
    @State var channel: ChannelController.ObservableObject?
    /// The `text` written in the message composer
    @State var text: String = ""
    /// Binding for message actions ActionSheet
    @State var actionSheetTrigger: Bool = false
    /// Message being edited
    @State var editingMessage: Message?
    
    init(channel channelBuilder: @autoclosure @escaping () -> ChannelController.ObservableObject) {
        self.channelBuilder = channelBuilder
    }
    
    var body: some View {
        VStack {
            self.messageList()
            self.composerView()
        }
        /// Channel ActionSheet presenter.
        .actionSheet(isPresented: $actionSheetTrigger, content: self.actionSheet)
        /// Set title to channel's name
        .navigationBarTitle(Text(channel?.channel?.extraData.name ?? "Unnamed Channel"), displayMode: .inline)
        /// Channel actions button
        .navigationBarItems(
            trailing: Button(action: { self.actionSheetTrigger = true }) {
                Image(systemName: "ellipsis")
            }
        )
        /// Initialize the `ChannelController`
        .onAppear {
            self.channel = self.channelBuilder()
        }
    }
    
    func messageList() -> some View {
        List(channel?.messages ?? [], id: \.self) { message in
            self.messageView(for: message)
                .onLongPressGesture { self.actionSheetTrigger = true; self.editingMessage = message }
        }
        .scaleEffect(x: 1, y: -1, anchor: .center)
        .offset(x: 0, y: 2)
    }
    
    func messageView(for message: Message) -> some View {
        let username = message.author.extraData.name ?? message.author.id
        let text: Text
        
        switch message.type {
        case .deleted:
            text = Text("❌ the message was deleted")
        case .error:
            text = Text("⚠️ something wrong happened")
        default:
            text = (Text(username).bold().foregroundColor(.forUsername(username)) + Text(" \(message.text)"))
        }
        
        return text
            /// Inverted list workaround
            .scaleEffect(x: 1, y: -1, anchor: .center)
            /// Load next more messages when the last is shown
            .onAppear {
                if (self.channel?.messages.last == message) {
                    self.channel?.controller.loadPreviousMessages()
                }
            }
    }
    
    func composerView() -> some View {
        HStack {
            TextField("Type a message", text: $text)
            Button(action: self.send) {
                Image(systemName: "arrow.up.circle.fill")
            }
        }.padding()
    }
    
    func send() {
        guard let channel = channel, let channelId = channel.channel?.cid else {
            return
        }
        
        if let editingMessage = self.editingMessage {
            let controller = channel.controller.client.messageController(cid: channelId, messageId: editingMessage.id)
            controller.editMessage(text: text)
            self.editingMessage = nil
        } else {
            channel.controller.createNewMessage(text: text)
        }

        text = ""
    }
    
    /// Action sheet with channel actions
    func actionSheet() -> ActionSheet {
        if let message = editingMessage {
            let messageController = channel?.controller.client.messageController(cid: channel!.channel!.cid, messageId: message.id)
            return ActionSheet(title: Text("Message Actions"), message: Text(""), buttons: [
                .default(Text("Edit"), action: { self.editingMessage = message; self.text = message.text }),
                .destructive(Text("Delete")) { messageController?.deleteMessage(); self.editingMessage = nil },
                .cancel { self.editingMessage = nil }
            ])
        } else {
            let userIds = Set(["steep-moon-9"])
            return ActionSheet(title: Text("Channel Actions"), message: Text(""), buttons: [
                .default(Text("Add Member"), action: { self.channel?.controller.addMembers(userIds: userIds) }),
                .default(Text("Remove Member"), action: { self.channel?.controller.removeMembers(userIds: userIds) }),
                .cancel()
            ])
        }
    }
}

/// Need to conform to Indentifiable for action sheet
extension Message: Identifiable {}
