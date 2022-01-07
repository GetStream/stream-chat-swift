//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

#if swift(>=5.3)

import Combine
import StreamChat
import SwiftUI

@available(iOS 14, *)
struct ChatView: View {
    /// The `ChannelController` used to interact with this channel. Will be synchronized in `onAppear`.
    @StateObject var channel: ChatChannelController.ObservableObject
    /// The `text` written in the message composer.
    @State var text: String = ""
    /// Binding for message actions and channel actions ActionSheet.
    @State var actionSheetTrigger: Bool = false
    /// Message being edited.
    @State var editingMessage: ChatMessage?
    /// Member list trigger.
    @State private var isShowingMemberList = false
    /// Search Messages trigger.
    @State private var isShowingMessageSearch = false

    var body: some View {
        VStack {
            self.messageList().layoutPriority(1)
            self.composerView()
            NavigationLink(destination: memberList, isActive: $isShowingMemberList) { EmptyView() }
            NavigationLink(destination: messageSearch, isActive: $isShowingMessageSearch) { EmptyView() }
            // This fixes a weird SwiftUI bug on 14.5: https://developer.apple.com/forums/thread/677333
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
        }
        /// ActionSheet presenter.
        .actionSheet(isPresented: $actionSheetTrigger, content: self.actionSheet)
        /// Set title to channel's name.
        .navigationBarTitle(
            Text(
                createTypingUserString(for: channel.channel) ??
                    createChannelTitle(for: channel.channel, channel.controller.client.currentUserId)
            ),
            displayMode: .inline
        )
        /// Channel actions button.
        .navigationBarItems(
            trailing: Button(action: { self.actionSheetTrigger = true }) {
                Image(systemName: "ellipsis")
            }
        )
        /// Initialize the `ChannelController`
        .onAppear(perform: { self.channel.controller.synchronize() })
    }
    
    func messageList() -> some View {
        ChatScrollView {
            ScrollViewReader { scrollView in
                LazyVStack(alignment: .leading) {
                    ForEach(channel.messages, id: \.self) { message in
                        self.messageView(for: message)
                    }
                }.onKeyboardAppear {
                    /// When the keyboard appears, we scroll to the latest message.
                    /// This resembles the behavior in Apple's Messages app.
                    if let firstMessage = channel.messages.first {
                        scrollView.scrollTo(firstMessage)
                    }
                }
            }
        }
    }
    
    func messageView(for message: ChatMessage) -> some View {
        let username = message.author.name ?? message.author.id
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
            .padding()
            .contextMenu {
                messageContextMenu(for: message)
            }
            /// Load next more messages when the last is shown.
            .onAppear {
                if self.channel.messages.first == message {
                    self.channel.controller.loadPreviousMessages()
                }
            }
    }
    
    func messageContextMenu(for message: ChatMessage) -> some View {
        VStack {
            if let cid = channel.controller.cid {
                let currentUserId = channel.controller.client.currentUserId
                let isMessageFromCurrentUser = message.author.id == currentUserId
                
                if isMessageFromCurrentUser {
                    let messageController = channel.controller.client.messageController(
                        cid: cid,
                        messageId: message.id
                    )

                    Button(action: { self.editingMessage = message; self.text = message.text }) {
                        Text("Edit")
                        Image(systemName: "pencil")
                    }
                    
                    Button(action: { messageController.deleteMessage() }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                } else {
                    let memberController = channel.controller.client.memberController(userId: message.author.id, in: cid)
                    
                    if message.author.isBanned {
                        Button(action: { memberController.unban() }) {
                            Text("Unban")
                            Image(systemName: "checkmark.square")
                        }
                    } else {
                        Button(action: { memberController.ban() }) {
                            Text("Ban")
                            Image(systemName: "exclamationmark.octagon")
                        }
                    }
                }
            }
        }
    }
    
    /// New message view with `TextEditor`.
    func composerView() -> some View {
        let textBinding = Binding(
            get: { self.text },
            set: { newValue in
                DispatchQueue.main.async {
                    self.text = newValue
                    self.didKeystroke()
                }
            }
        )
        
        return HStack {
            ZStack {
                if text.isEmpty {
                    Text("Type a message")
                        .foregroundColor(.secondary)
                        .padding(.all, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(text) // hack to auto expand the composer (TextEditor alone won't do it)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.all, 8)
                        .opacity(0)
                }
                
                TextEditor(text: textBinding).background(Color.clear).onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
            }
            Button(action: self.send) {
                Image(systemName: "arrow.up.circle.fill")
            }
        }.padding()
    }
    
    /// Send new message or edit message request if you are in editing state.
    func send() {
        guard let channelId = channel.channel?.cid else {
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
    
    /// ActionSheet for channel action or message actions depending on `editingMessage` value.
    /// This is done due to `SwiftUI` limitations: it's not possible to have multiple `.actionSheet` modifiers.
    func actionSheet() -> ActionSheet {
        ActionSheet(title: Text("Channel Actions"), buttons: [
            .default(
                Text("Edit Members"), action: {
                    self.isShowingMemberList = true
                }
            ),
            .default(
                Text("Search messages"), action: {
                    self.isShowingMessageSearch = true
                }
            ),
            .cancel()
        ])
    }
    
    /// `MemberListView` for channel memebers.
    var memberList: some View {
        let controller = channel.controller.client.memberListController(query: .init(cid: channel.channel!.cid))
        return MemberListView(channel: channel, memberList: controller.observableObject)
    }

    var messageSearch: some View {
        let messageSearch = channel.controller.client.messageSearchController()
        return SearchMessagesView(messagesSearch: messageSearch.observableObject)
    }
    
    private func didKeystroke() {
        channel.controller.sendKeystrokeEvent()
    }
    
    private func didStopTyping() {
        channel.controller.sendStopTypingEvent()
    }
}

@available(iOS 14, *)
struct SearchMessagesView: View {
    @StateObject var messagesSearch: ChatMessageSearchController.ObservableObject

    @State private var text: String = "" {
        didSet {
            messagesSearch.controller.search(text: text)
        }
    }

    var body: some View {
        VStack {
            TextField("Search for messages...", text: $text)
                .padding()
                .background(Color.gray.opacity(0.2))
                .onChange(of: text) { text in
                    messagesSearch.controller.search(text: text)
                }

            ChatScrollView {
                ScrollViewReader { _ in
                    LazyVStack(alignment: .leading) {
                        ForEach(messagesSearch.messages, id: \.self) { message in
                            self.messageView(for: message)
                        }
                    }
                }
            }
        }
    }

    func messageView(for message: ChatMessage) -> some View {
        let username = message.author.name ?? message.author.id
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
    }
}

#endif
