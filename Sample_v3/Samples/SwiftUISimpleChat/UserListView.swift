//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChatClient
import SwiftUI

@available(iOS 14, *)
struct UserListView: View {
    /// The `ChatUserListController` used to interact with this users. Will be synchronized in `onAppear`.
    @StateObject var userList: ChatUserListController.ObservableObject
    
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
                    Text(userList.users[index].name ?? "Missing name")
                        /// Pagination.
                        .onAppear(perform: { self.loadNextIfNecessary(encounteredIndex: index) })
                }
            }
        }
        .onAppear { userList.controller.synchronize() }
    }
    
    /// Pagination. Load next channels if last item is reached.
    private func loadNextIfNecessary(encounteredIndex: Int) {
        guard encounteredIndex == userList.users.count - 1 else { return }
        userList.controller.loadNextUsers()
    }
}
