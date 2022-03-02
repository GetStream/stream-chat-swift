//
//  UserListViewModel.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 25/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

public class UserListViewModel: NSObject {
    // MARK: - VARIABLE
    public enum ChatUserLoadingState {
        case searching,searchingError, loading, loadMoreData, error, completed , none
    }
    var bCallbackDataLoadingStateUpdated: ((UserListViewModel.ChatUserLoadingState) -> Void)?
    var bCallbackDataUserList: (([ChatUser]) -> Void)?
    public lazy var dataLoadingState = UserListViewModel.ChatUserLoadingState.none {
        didSet {
            self.bCallbackDataLoadingStateUpdated?(dataLoadingState)
        }
    }
    public var searchText: String?
    public lazy var selectedUsers = [ChatUser]()
    public lazy var existingUsers = [ChatUser]()
    public var sortType:Em_ChatUserListFilterTypes
    private lazy var userListController: ChatUserListController = {
        return ChatClient.shared.userListController()
    }()
    private lazy var serachListController: ChatUserSearchController = {
        return ChatClient.shared.userSearchController()
    }()
    private var searchOperation: DispatchWorkItem?
    private let throttleTime = 1000
    private var loadingPreviousData: Bool = false
    private var hasLoadedAllData: Bool = false
    private var pageSize: Int = 100
    public lazy var sectionWiseUserList = [ChatUserListData]()
    // MARK: - INIT
    init(sortType: Em_ChatUserListFilterTypes) {
        self.sortType = sortType
        super.init()
        self.userListController.delegate = self
    }
    // MARK: - METHOD
    public func isUserSelected(chatUser: ChatUser) -> Int? {
        return self.selectedUsers.firstIndex(where: { $0.id.lowercased() == chatUser.id.lowercased()})
    }
}
// MARK: - SORT METHODS
extension UserListViewModel {
    public func shortAtoZ(filteredUsers: [ChatUser]) -> ChatUserListData {
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        var data = ChatUserListData.init(letter: "", sectionType: .noHeader)
        data.users = alphabetUsers
        data.users.append(contentsOf: otherUsers)
        return data
    }
    public func shortLastSeen(filteredUsers: [ChatUser]) -> ChatUserListData{
        let onlineUser = filteredUsers.filter({ $0.isOnline && $0.name?.isBlank == false }).sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let alphabetUsers = onlineUser.filter { ($0.name?.isFirstCharacterAlp ?? false) }
        let nonAphabetUsers = onlineUser.filter { ($0.name?.isFirstCharacterAlp ?? false) == false}
        let otherUsers = filteredUsers.filter({ $0.isOnline == false && $0.name?.isBlank == false}).sorted(by: { ($0.lastActiveAt ?? $0.userCreatedAt) > ($1.lastActiveAt ?? $1.userCreatedAt )})
        var data = ChatUserListData.init(letter: "", sectionType: .noHeader)
        data.users = alphabetUsers
        data.users.append(contentsOf: nonAphabetUsers)
        data.users.append(contentsOf: otherUsers)
        return data
    }
    public func shortByName(filteredUsers: [ChatUser]) -> [ChatUserListData] {
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        let groupByName = Dictionary(grouping: alphabetUsers) { (user) -> Substring in
            return user.name!.lowercased().prefix(1)
        }
        var data = [ChatUserListData]()
        let keys = groupByName.keys.sorted()
        keys.forEach { item  in
            data.append(ChatUserListData.init(letter: String(item), sectionType: .aphabetHeader, users: groupByName[item] ?? []))
        }
        if !otherUsers.isEmpty {
            data.append(ChatUserListData.init(letter: "#", sectionType: .aphabetHeader, users: otherUsers))
        }
        return data
    }
}
// MARK: - GET STREAM API
extension UserListViewModel {
    public func searchDataUsing(searchString: String?) {
        if self.dataLoadingState != .searching {
            self.dataLoadingState = .searching
        }
        searchOperation?.cancel()
        searchOperation = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.searchUser(with: searchString)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: searchOperation!)
    }
    
    private func searchUser(with name: String?) {
        self.searchText = name
        if let strName = name, strName.isEmpty == false {
            if strName.containsEmoji  || strName.isBlank {
                Snackbar.show(text: "Please enter valid name")
                self.dataLoadingState = .searchingError
                return
            }
            var newQuery = self.serachListController.query
            newQuery.filter = .and([
                .autocomplete(.name, text: strName),
                .exists(.lastActiveAt),
                .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
            ])
            serachListController.search(query: newQuery) { [weak self] error in
                guard let weakSelf = self else { return }
                if let error = error {
                    weakSelf.dataLoadingState = .searchingError
                } else {
                    let filterData = weakSelf.serachListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
                    weakSelf.bCallbackDataUserList?(filterData)
                    weakSelf.dataLoadingState = .completed
                }
            }
        } else {
            self.searchText = nil
            self.fetchUserList()
        }
    }
    
    open func fetchUserList(_ fetchMoreData: Bool = false) {
        guard self.searchText == nil else {
            return
        }
        if self.dataLoadingState != .loading && fetchMoreData == false {
            self.dataLoadingState = .loading
        }
        if fetchMoreData {
            self.dataLoadingState = .loadMoreData
            var userQuery = UserListQuery(filter: .and([
                .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
            ]), sort: [], pageSize: 99)
            self.userListController = ChatClient.shared.userListController(query: userQuery)
            self.userListController.synchronize { [weak self] error in
                guard let weakSelf = self else { return }
                if error == nil {
                    let filterData = weakSelf.userListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
                    weakSelf.bCallbackDataUserList?(filterData)
                    weakSelf.dataLoadingState = .completed
                    return
                }
                weakSelf.dataLoadingState = .error
            }
        } else {
            let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let userQuery = UserListQuery.init(filter: .greaterOrEqual(.lastActiveAt, than: date), sort: [], pageSize: 99)
            self.userListController.query = userQuery
            self.userListController.synchronize { [weak self] error in
                guard let weakSelf = self else { return }
                if error == nil {
                    let filterData = weakSelf.userListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
                    weakSelf.bCallbackDataUserList?(filterData)
                    weakSelf.dataLoadingState = .completed
                    return
                }
                weakSelf.dataLoadingState = .error
            }
        }
    }
    
    open func sortUserList() {
        if let strName = searchText, strName.isBlank == false {
            let filterData = self.serachListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
            self.bCallbackDataUserList?(filterData)
        } else  {
            let filterData = self.userListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
            self.bCallbackDataUserList?(filterData)
        }
    }
}
// MARK: - Chat user controller delegate
extension UserListViewModel: ChatUserListControllerDelegate {
    public func controller(_ controller: ChatUserListController, didChangeUsers changes: [ListChange<ChatUser>]) {
        // To Do
    }
}
public struct DTFormatter {
    public static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
