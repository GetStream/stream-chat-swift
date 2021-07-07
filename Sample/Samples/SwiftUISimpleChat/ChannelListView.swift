//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

#if swift(>=5.3)

import Combine
import StreamChat
import SwiftUI

@available(iOS 14, *)
struct ChannelListView: View {
    /// The `ChatChannelListController` used to interact with this channel. Will be synchronized in `onAppear`.
    @StateObject var channelList: ChatChannelListController.ObservableObject
    /// Binding for channel actions ActionSheet.
    @State private var showActionSheet: ChannelId?
    /// Binding for ChatView navigation.
    @State private var showDetails: Int?
    /// Binding for add channel alert.
    @State private var showAddChannelAlert: Bool = false
    /// Binding for showing `sheet`s
    @State private var activeSheet: ActiveSheet?
    
    /// Definition of alert shown when add channel button is pressed.
    var addChannelAlert: TextAlert {
        let id = UUID().uuidString
        let defaultName = "Channel" + id.prefix(4)
        
        return TextAlert(title: "Create channel", placeholder: defaultName) { name in
            do {
                let controller = try self.channelList.controller.client.channelController(
                    createChannelWithId: .init(type: .messaging, id: id),
                    name: name,
                    imageURL: nil,
                    extraData: .defaultValue
                )
                controller.synchronize()
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    var body: some View {
        VStack {
            /// Loading indicator will appear when there is no channels in local storage and `synchronize()` is in progress.
            if channelList.state != .remoteDataFetched && channelList.channels.isEmpty {
                ProgressView("Loading channels...")
            }
            List {
                /// Range version is used here for pagination.
                ForEach(0..<channelList.channels.count, id: \.self) { index in
                    /// Navigation for ChatView
                    NavigationLink(destination: chatView(for: index), tag: index, selection: self.$showDetails) {
                        self.channelView(for: index)
                            /// Workaround for gestures to work with the whole cell.
                            .contentShape(Rectangle())
                            /// Open ChatView on tap.
                            .onTapGesture { showDetails = index }
                            /// Show ActionSheet on long press.
                            .onLongPressGesture { showActionSheet = channel(index).cid }
                            /// Pagination.
                            .onAppear(perform: { loadNextIfNecessary(encounteredIndex: index) })
                    }
                }
                /// Swipe to delete action.
                .onDelete(perform: deleteChannel)
            }
        }
        /// ActionSheet presenter.
        .actionSheet(item: $showActionSheet, content: actionSheet)
        /// Add channel alert presenter
        .alert(isPresented: $showAddChannelAlert, addChannelAlert)
        .navigationBarTitle("Channels")
        /// Settings and create channel buttons.
        .navigationBarItems(leading: showSettingsButton, trailing: HStack { usersButton; addChannelButton })
        /// Modal view presenter
        .sheet(item: $activeSheet) { item in
            switch item {
            /// Show settings.
            case .settings:
                SettingsView(currentUserController: channelList.controller.client.currentUserController())
            /// Show list of users.
            case .users:
                userListView
            }
        }
        /// Synchronize local data with remote.
        .onAppear(perform: { self.channelList.controller.synchronize() })
    }
    
    // MARK: - Views
    
    /// `ActionSheet` with many actions that can be taken on the `channelController` such
    /// as `updateChannel`, `muteChannel`, `unmuteChannel`, ``showChannel`, and `hideChannel`.
    /// Will appear on long pressing the channel cell.
    private func actionSheet(for cid: ChannelId) -> ActionSheet {
        let channelController = channelList.controller.client.channelController(for: cid)
        return ActionSheet(title: Text(cid.id), message: Text(""), buttons: [
            .default(Text("Show")) { channelController.showChannel() },
            .default(Text("Hide")) { channelController.hideChannel() },
            .default(Text("Mute")) { channelController.muteChannel() },
            .default(Text("Unmute")) { channelController.unmuteChannel() },
            .cancel()
        ])
    }
    
    /// Add channel button. To create new channel we need to get a new `ChannelController`
    /// with `chatClient.channelController(createChannelWithId: ...)`
    /// and call `synchronize()` on it.
    var addChannelButton: some View {
        Button(action: {
            self.showAddChannelAlert = true
        }) {
            Image(systemName: "plus.bubble").imageScale(.large)
        }
    }
    
    /// Channel cell container view.
    private func channelView(for index: Int) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(createChannelTitle(for: channel(index), channelList.controller.client.currentUserId))
                    .lineLimit(1)
                    .font(.system(
                        size: UIFontMetrics.default.scaledValue(for: 19),
                        /// Highlight channel name on unread messages.
                        weight: channel(index).isUnread ? .medium : .regular,
                        design: .default
                    ))
                /// Latest message subtitle.
                self.channelDetails(for: index)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(.accentColor)
            }
            Spacer()
            /// Unread count.
            unreadCountCircle(for: channel(index))
        }
    }
    
    /// Button that will open `UserListView`.
    var usersButton: some View {
        Button(action: {
            activeSheet = .users
        }) {
            Image(systemName: "person.3.fill").imageScale(.large)
        }
    }
    
    /// `UserLisView` for users matching the query.
    var userListView: some View {
        let controller = channelList.controller.client.userListController()
        return UserListView(
            userList: controller.observableObject,
            didSelectUser: { userId in
                activeSheet = nil
                openDirectMessages(with: userId)
            }
        )
    }
    
    /// Button that will open `SettingsView`.
    var showSettingsButton: some View {
        Button(action: {
            self.activeSheet = .settings
        }) {
            Image(systemName: "gear").imageScale(.large)
        }
    }
    
    /// Unread count number in circle.
    func unreadCountCircle(for channel: ChatChannel) -> AnyView {
        if channel.isUnread {
            return AnyView(
                Text("\(channel.unreadCount.messages)")
                    .fontWeight(.bold)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().foregroundColor(.accentColor))
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    /// Formatted channel details.
    private func channelDetails(for index: Int) -> Text {
        let channel = self.channel(index)
        
        if let typingUsersInfo = createTypingUserString(for: channel) {
            return Text(typingUsersInfo)
        } else if let latestMessage = channel.latestMessages.first {
            let author = latestMessage.author.name ?? latestMessage.author.id.description
            return Text("\(author): \(latestMessage.text)")
        } else {
            return Text("No messages")
        }
    }
    
    // MARK: - Actions
    
    /// Pagination. Load next channels if last item is reached.
    private func loadNextIfNecessary(encounteredIndex: Int) {
        guard encounteredIndex == channelList.channels.count - 1 else { return }
        channelList.controller.loadNextChannels()
    }
    
    /// Delete channel action for swipe-to-delete.
    private func deleteChannel(for indexSet: IndexSet) {
        indexSet.forEach { index in
            channelList.controller.client.channelController(for: self.channel(index).cid).deleteChannel()
        }
    }
    
    // MARK: - Helpers
    
    private func channel(_ index: Int) -> ChatChannel {
        channelList.channels[index]
    }
    
    private func chatView(for index: Int) -> ChatView {
        let channelController = channelList.controller.client.channelController(
            for: channelList.channels[index].cid
        )
        
        channelController.listOrdering = .bottomToTop
        
        return ChatView(channel: channelController.observableObject)
    }
    
    private func openDirectMessages(with userId: UserId) {
        // TODO: Show a `ChatView` with the controller that creates new 1-1 channel.
    }
}

/// We need to conform to this protocol for displaying ActionSheet for specific item.
/// ChannelId already conforms to protocol cause it has `id` property.
extension ChannelId: Identifiable {}

enum ActiveSheet: Identifiable {
    case settings, users
    
    var id: Int {
        hashValue
    }
}

#endif
