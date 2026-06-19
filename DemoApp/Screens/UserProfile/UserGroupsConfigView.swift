//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 15, *)
struct UserGroupsConfigView: View {
    let client: ChatClient

    @State private var groups: [UserGroup] = []
    @State private var searchText = ""
    @State private var searchResults: [UserGroup] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var hasLoadedAllUserGroups = false
    @State private var showCreateAlert = false
    @State private var newGroupName = ""
    @State private var selectedGroup: UserGroup?
    @State private var searchDebouncer = Debouncer(0.3, queue: .main)
    @State private var listController: UserGroupListController

    init(client: ChatClient) {
        self.client = client
        _listController = State(initialValue: client.userGroupListController())
    }

    private var displayedGroups: [UserGroup] {
        searchText.isEmpty ? groups : searchResults
    }

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            if displayedGroups.isEmpty && !isLoading {
                Text(searchText.isEmpty ? "No groups loaded" : "No groups found")
                    .foregroundColor(.secondary)
            }

            ForEach(displayedGroups) { group in
                Button {
                    selectedGroup = group
                } label: {
                    groupRow(group)
                }
                .onAppear {
                    loadMoreGroupsIfNeeded(for: group)
                }
            }

            if searchText.isEmpty, !groups.isEmpty {
                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if hasLoadedAllUserGroups {
                    Text("All groups loaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search groups")
        .onChange(of: searchText) { newValue in
            handleSearchTextChange(newValue)
        }
        .navigationTitle("User Groups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateAlert = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(isLoading)
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            loadGroups()
        }
        .alert("Create User Group", isPresented: $showCreateAlert) {
            TextField("Name", text: $newGroupName)
            Button("Create") {
                createGroup()
            }
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
        }
        .sheet(item: $selectedGroup) { group in
            NavigationView {
                UserGroupDetailView(
                    client: client,
                    listController: listController,
                    group: group,
                    onChanged: loadGroups
                )
            }
        }
    }

    @ViewBuilder
    private func groupRow(_ group: UserGroup) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(.headline)
            Text(group.id)
                .font(.caption)
                .foregroundColor(.secondary)
            if !group.members.isEmpty {
                Text("\(group.members.count) members")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func loadGroups() {
        isLoading = true
        errorMessage = nil

        listController.synchronize { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    groups = listController.userGroups
                    hasLoadedAllUserGroups = listController.hasLoadedAllUserGroups
                }
            }
        }
    }

    private func loadMoreGroupsIfNeeded(for group: UserGroup) {
        guard searchText.isEmpty else { return }
        guard !isLoading, !isLoadingMore, !hasLoadedAllUserGroups else { return }
        guard group.id == groups.last?.id else { return }

        isLoadingMore = true
        errorMessage = nil

        listController.loadMoreUserGroups { error in
            DispatchQueue.main.async {
                isLoadingMore = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    groups = listController.userGroups
                    hasLoadedAllUserGroups = listController.hasLoadedAllUserGroups
                }
            }
        }
    }

    private func handleSearchTextChange(_ newValue: String) {
        let query = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            searchDebouncer.invalidate()
            searchResults = []
            return
        }

        var debouncer = searchDebouncer
        debouncer.execute {
            searchGroups(with: query)
        }
        searchDebouncer = debouncer
    }

    private func searchGroups(with query: String) {
        isLoading = true
        errorMessage = nil

        listController.searchUserGroups(text: query) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case let .success(groups):
                    searchResults = groups
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func createGroup() {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        newGroupName = ""

        listController.createUserGroup(name: name) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    loadGroups()
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

@available(iOS 15, *)
private struct UserGroupDetailView: View {
    let client: ChatClient
    let listController: UserGroupListController
    let onChanged: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var group: UserGroup
    @State private var newMemberId = ""
    @State private var newGroupName = ""
    @State private var showAddMemberAlert = false
    @State private var showRenameAlert = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var controller: UserGroupController

    init(
        client: ChatClient,
        listController: UserGroupListController,
        group: UserGroup,
        onChanged: @escaping () -> Void
    ) {
        self.client = client
        self.listController = listController
        self.onChanged = onChanged
        _group = State(initialValue: group)
        _controller = State(initialValue: client.userGroupController(userGroupId: group.id, teamId: group.teamId))
    }

    var body: some View {
        Form {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Section("Details") {
                detailRow(title: "ID", value: group.id)
                detailRow(title: "Name", value: group.name)
                if let description = group.description {
                    detailRow(title: "Description", value: description)
                }
                if let teamId = group.teamId {
                    detailRow(title: "Team", value: teamId)
                }
            }

            Section("Members") {
                if group.members.isEmpty {
                    Text("No members")
                        .foregroundColor(.secondary)
                }

                ForEach(group.members, id: \.userId) { member in
                    HStack {
                        Text(member.userId)
                        Spacer()
                        if member.isAdmin {
                            Text("Admin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            removeMember(userId: member.userId)
                        } label: {
                            Label("Remove", systemImage: "person.fill.xmark")
                        }
                    }
                }

                Button("Add Member") {
                    newMemberId = ""
                    showAddMemberAlert = true
                }
                .disabled(isLoading)
            }

            Section {
                Button("Rename") {
                    newGroupName = group.name
                    showRenameAlert = true
                }
                .disabled(isLoading)

                Button("Delete Group", role: .destructive) {
                    deleteGroup()
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            refreshGroup()
        }
        .alert("Add Member", isPresented: $showAddMemberAlert) {
            TextField("User ID", text: $newMemberId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Add") {
                addMember()
            }
            Button("Cancel", role: .cancel) {
                newMemberId = ""
            }
        }
        .alert("Rename User Group", isPresented: $showRenameAlert) {
            TextField("Name", text: $newGroupName)
            Button("Save") {
                updateGroup()
            }
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func refreshGroup() {
        isLoading = true
        errorMessage = nil

        controller.synchronize { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else if let updatedGroup = controller.userGroup {
                    group = updatedGroup
                }
            }
        }
    }

    private func updateGroup() {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        newGroupName = ""

        controller.update(name: name) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case let .success(updatedGroup):
                    group = updatedGroup
                    onChanged()
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func deleteGroup() {
        isLoading = true
        errorMessage = nil

        listController.deleteUserGroup(id: group.id, teamId: group.teamId) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error {
                    errorMessage = error.localizedDescription
                } else {
                    onChanged()
                    dismiss()
                }
            }
        }
    }

    private func addMember() {
        let userId = newMemberId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        newMemberId = ""

        controller.addMembers([userId]) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case let .success(updatedGroup):
                    group = updatedGroup
                    onChanged()
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func removeMember(userId: String) {
        isLoading = true
        errorMessage = nil

        controller.removeMembers([userId]) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case let .success(updatedGroup):
                    group = updatedGroup
                    onChanged()
                case let .failure(error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
