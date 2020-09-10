//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChatClient
import SwiftUI

@available(iOS 13, *)
struct ChannelListView: View {
    // TODO: It's safer to use `@StateObject` here because `@ObservedObject` can sometimes release the
    // reference and this will crash.
    @ObservedObject var channelList: ChannelListController.ObservableObject
    /// Binding for channel actions ActionSheet
    @State private var showActionSheet: ChannelId?
    /// Binding for ChatView navigation
    @State private var showDetails: Int?
    /// Binding for SettingsView
    @State private var showSettings: Bool = false
        
    private lazy var cancellables: Set<AnyCancellable> = []
    
    init(channelList: ChannelListController.ObservableObject) {
        self.channelList = channelList
        
        /// Dummy binding for State changes.
        /// You can also observe State on `ChannelListController.ObservableObject`.
        channelList.controller
            .statePublisher
            .sink(receiveValue: {
                print("State change: \($0)")
            })
            .store(in: &cancellables)
        
        /// Dummy binding for channels changes.
        channelList.controller
            .channelsChangesPublisher
            .sink(receiveValue: {
                print("Channels changes: \($0)")
            })
            .store(in: &cancellables)
    }
    
    var body: some View {
        VStack {
            List {
                /// Range version is used here for pagination.
                ForEach(0..<channelList.channels.count, id: \.self) { index in
                    /// Navigation for ChatView
                    NavigationLink(destination: self.chatView(for: index), tag: index, selection: self.$showDetails) {
                        self.channelView(for: index)
                            /// Workaround for gestures to work with the whole cell.
                            .contentShape(Rectangle())
                            /// Open ChatView on tap.
                            .onTapGesture { self.showDetails = index }
                            /// Show ActionSheet on long press.
                            .onLongPressGesture { self.showActionSheet = self.channel(index).cid }
                            /// Pagination.
                            .onAppear(perform: { self.loadNextIfNecessary(encounteredIndex: index) })
                    }
                }
                /// Swipe to delete action.
                .onDelete(perform: deleteChannel)
            }
        }
        /// ActionSheet presenter.
        .actionSheet(item: $showActionSheet, content: self.actionSheet)
        .navigationBarTitle("Channels")
        /// Settings and create channel buttons.
        .navigationBarItems(leading: showSettingsButton, trailing: addChannelButton)
        /// Settings presenter.
        .sheet(isPresented: $showSettings, content: { SettingsView() })
    }
    
    // MARK: - Views
    
    private func channelView(for index: Int) -> AnyView {
        AnyView(
            HStack {
                VStack(alignment: .leading) {
                    Text(self.channel(index).name)
                        .lineLimit(1)
                        .font(.system(
                            size: 19,
                            /// Highlight channel name on unread messages.
                            weight: self.channel(index).isUnread ? .medium : .regular,
                            design: .default
                        ))
                    /// Latest message subtitle.
                    self.latestMessage(for: index)
                        .lineLimit(1)
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
                Spacer()
                /// Unread count.
                unreadCountCircle(for: self.channel(index))
            }
        )
    }
    
    /// Action sheet with channel actions.
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
    
    var showSettingsButton: AnyView {
        AnyView(
            Button(action: {
                self.showSettings = true
            }) {
                Image(systemName: "gear").imageScale(.large)
            }
        )
    }
    
    var addChannelButton: AnyView {
        AnyView(
            Button(action: {
                let id = UUID().uuidString
                let controller = self.channelList.controller.client.channelController(
                    createChannelWithId: .init(type: .messaging, id: id),
                    members: [self.channelList.controller.client.currentUserId],
                    extraData: .init(name: "Channel" + id.prefix(4), imageURL: nil)
                )
                controller.startUpdating()
            }) {
                Image(systemName: "plus.bubble").imageScale(.large)
            }
        )
    }
    
    /// Unread count number in circle.
    func unreadCountCircle(for channel: Channel) -> AnyView {
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
    
    private func latestMessage(for index: Int) -> Text {
        guard let latestMessage = channel(index).latestMessages.first else {
            return Text("No messages")
        }
        
        let author = latestMessage.author.name ?? latestMessage.author.id.description
        return Text("\(author): \(latestMessage.text)")
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
    
    private func channel(_ index: Int) -> Channel {
        channelList.channels[index]
    }
    
    private func chatView(for index: Int) -> ChatView {
        ChatView(channelId: channelList.channels[index].cid)
    }
}

/// We need to conform to this protocol for displaying ActionSheet for specific item.
/// ChannelId already conforms to protocol cause it has `id` property.
extension ChannelId: Identifiable {}

private extension Channel {
    var name: String { extraData.name ?? cid.description }
}
