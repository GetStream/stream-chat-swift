//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

#if swift(>=5.3)

import Combine
import StreamChat
import SwiftUI

@available(iOS 14, *)
struct UserListView: View {
    /// The `ChatUserListController` used to interact with this users. Will be synchronized in `onAppear`.
    @StateObject var userList: ChatUserListController.ObservableObject
    /// Binding for user actions ActionSheet.
    @State private var showActionSheet: ChatUser?
    /// The callback that is called when a user is selected.
    let didSelectUser: (UserId) -> Void
    
    var body: some View {
        VStack {
            /// Loading indicator will appear when there is no users in local storage and `synchronize()` is in progress.
            if userList.state != .remoteDataFetched && userList.users.isEmpty {
                ProgressView("Loading channels...")
            }
            /// List of users matching the query.
            List {
                /// Range version is used here for pagination.
                ForEach(0..<userList.users.count, id: \.self) { index in
                    userView(for: userList.users[index])
                        /// Workaround for gestures to work with the whole cell.
                        .contentShape(Rectangle())
                        /// On tap gesture direct message channel will be created and you will be directed back to channel list.
                        .onTapGesture { didSelectUser(userList.users[index].id) }
                        /// Show ActionSheet on long press.
                        .onLongPressGesture { showActionSheet = userList.users[index] }
                        /// Pagination.
                        .onAppear(perform: { loadNextIfNecessary(encounteredIndex: index) })
                }
            }
        }
        /// ActionSheet presenter.
        .actionSheet(item: $showActionSheet, content: actionSheet)
        .onAppear { userList.controller.synchronize() }
    }
    
    /// View with user name and mute icon if user is muted.
    private func userView(for user: ChatUser) -> some View {
        let isUserMuted = (
            userList.controller.client.currentUserController().currentUser?.mutedUsers
                .contains(where: { $0.id == user.id })
        )!
        return HStack {
            Text(user.name ?? "Missing name")
            Spacer()
            /// Show `mute` icon if user is muted.
            if isUserMuted {
                Image(systemName: "speaker.slash.fill")
            }
        }
    }
    
    /// `ActionSheet` with actions that can be taken on the `userController`(`mute`, `unmute`)
    /// Will appear on long pressing the user cell.
    private func actionSheet(for user: ChatUser) -> ActionSheet {
        let userController = userList.controller.client.userController(userId: user.id)
        return ActionSheet(title: Text(user.name ?? "User name"), message: Text(""), buttons: [
            .default(Text("Mute")) { userController.mute() },
            .default(Text("Unmute")) { userController.unmute() },
            .cancel()
        ])
    }
    
    /// Pagination. Load next channels if last item is reached.
    private func loadNextIfNecessary(encounteredIndex: Int) {
        guard encounteredIndex == userList.users.count - 1 else { return }
        userList.controller.loadNextUsers()
    }
}

#endif
