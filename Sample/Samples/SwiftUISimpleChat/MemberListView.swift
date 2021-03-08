//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

#if swift(>=5.3)

import Combine
import StreamChat
import SwiftUI

@available(iOS 14, *)
struct MemberListView: View {
    /// The `ChannelController` used to interact with the channel.
    let channel: ChatChannelController.ObservableObject
    /// The observable wrapper around `ChatChannelMemberListController` used to interact with channel members.
    /// Will be synchronized in `onAppear`.
    @StateObject var memberList: ChatChannelMemberListController.ObservableObject
    /// The trigger that controls `UserListView` visability.
    @State private var isShowingUserList = false
    
    var body: some View {
        VStack {
            /// Loading indicator will appear when there are no members in local storage and `synchronize()` is in progress.
            if memberList.state != .remoteDataFetched && memberList.members.isEmpty {
                ProgressView("Loading members...")
            }
            /// List of channel members matching the query.
            List {
                /// Range version is used here for pagination.
                ForEach(0..<memberList.members.count, id: \.self) { index in
                    memberView(for: memberList.members[index])
                        /// Pagination.
                        .onAppear(perform: { loadNextIfNecessary(encounteredIndex: index) })
                }
            }
        }
        .onAppear { memberList.controller.synchronize() }
        /// Set the title.
        .navigationBarTitle(Text("Members"), displayMode: .inline)
        /// Navigation bar button user to open a user list.
        .navigationBarItems(trailing: userListButton)
        /// Show user list view.
        .sheet(isPresented: $isShowingUserList, content: { userList })
    }
    
    /// The user list used to add new channel members.
    private var userList: some View {
        UserListView(
            userList: memberList.controller.client.userListController().observableObject,
            didSelectUser: { userId in
                addNewChannelMember(with: userId) {
                    isShowingUserList = false
                }
            }
        )
    }
    
    /// Button for user list navigation.
    private var userListButton: some View {
        Button(
            action: { isShowingUserList = true }
        ) {
            Image(systemName: "plus")
        }
    }
    
    /// View for member.
    private func memberView(for member: ChatChannelMember) -> some View {
        let isCurrentUser = member.id == memberList.controller.client.currentUserId
        
        return HStack {
            VStack(alignment: .leading) {
                Text(createMemberNameAndStatusInfoString(for: member, isCurrentUser: isCurrentUser))
                    .foregroundColor(member.name.flatMap(Color.forUsername) ?? .black)
                    .bold()

                if let onlineStatus = createMemberOnlineStatusInfoString(for: member) {
                    Text(onlineStatus)
                        .foregroundColor(member.isOnline ? .blue : .gray)
                }
            }
            
            Spacer()
            
            if let role = createMemberRoleString(for: member) {
                Text(role)
            }
        }
        .contextMenu {
            if canTakeAnAction(on: member) {
                memberContextMenu(for: member)
            }
        }
    }
    
    /// Pagination. Load next members if last item is reached.
    private func loadNextIfNecessary(encounteredIndex: Int) {
        guard encounteredIndex == memberList.members.count - 1 else { return }
        memberList.controller.loadNextMembers()
    }
    
    /// Adds new channel member.
    private func addNewChannelMember(with userId: UserId, completion: @escaping () -> Void) {
        channel.controller.addMembers(userIds: [userId]) { _ in
            completion()
        }
    }
    
    /// Bans/unbans the channel member.
    private func revertBan(for member: ChatChannelMember) {
        let memberController = memberList.controller.client.memberController(
            userId: member.id,
            in: memberList.controller.query.cid
        )

        let actionCompletion: (Error?) -> Void = { [memberController] _ in
            _ = memberController
        }
        
        if member.isBanned {
            memberController.unban(completion: actionCompletion)
        } else {
            memberController.ban(completion: actionCompletion)
        }
    }
    
    func canTakeAnAction(on member: ChatChannelMember) -> Bool {
        guard
            // Verify current user is a channel member.
            let currentUser = memberList.members.first(where: { $0.id == memberList.controller.client.currentUserId }),
            // Verify current user is a moderator.
            currentUser.memberRole != .member,
            // Verify selected member is not a current user.
            currentUser.id != member.id
        else { return false }
        
        return true
    }
    
    /// Creates the context menu with allowed actions.
    func memberContextMenu(for member: ChatChannelMember) -> some View {
        VStack {
            Button(action: { revertBan(for: member) }) {
                Text(member.isBanned ? "Unban" : "Ban")
            }
            Button(action: { channel.controller.removeMembers(userIds: [member.id]) }) {
                Text("Delete from channel")
                Image(systemName: "trash")
            }
        }
    }
}

#endif
