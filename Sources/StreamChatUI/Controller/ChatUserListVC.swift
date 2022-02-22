//
//  ChatUserListVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 07/02/22.
//

import UIKit
import Nuke
import StreamChat
import StreamChatUI

public struct ChatUserListData {
    let letter: String
    var users = [ChatUser]()
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
public protocol ChatUserListDelegate: AnyObject {
    func chatListStateUpdated(state: ChatUserListVC.ChatUserLoadingState)
    func chatUserDidSelect()
}
public class ChatUserListVC: UIViewController {
    //
    public enum ChatUserLoadingState {
        case searching, loading, noUsers, selected, error, completed
    }
    public enum ChatUserSelectionType {
        case singleUser, group, privateGroup , addFriend
    }
    //
    // MARK: - @IBOutlet
    @IBOutlet private weak var searchFieldStack: UIStackView!
    @IBOutlet private weak var searchBarContainerView: UIView!
    @IBOutlet private weak var searchBarView: UIView!
    @IBOutlet private weak var daoButton: UIButton!
    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var alertView: UIView!
    @IBOutlet private weak var alertImage: UIImageView!
    @IBOutlet private weak var alertText: UILabel!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var noMatchView: UIView!
    //
    // MARK: - VARIABLES
    private lazy var userListController: ChatUserListController = {
        return ChatClient.shared.userListController()
    }()
    private lazy var serachListController: ChatUserSearchController = {
        return ChatClient.shared.userSearchController()
    }()
    @IBOutlet private weak var tableView: UITableView?
    public var selectedUsers = [ChatUser]()
    public var existingUsers = [ChatUser]()
    public var userSelectionType = ChatUserSelectionType.singleUser
    public var curentSortType: Em_ChatUserListFilterTypes = .sortByLastSeen
    private var nameWiseUserList = [ChatUserListData]()
    private var lastSeenWiseUserList = [ChatUser]()
    //
    private var dataLoadingState = ChatUserLoadingState.error
    //
    private var searchOperation: DispatchWorkItem?
    private let throttleTime = 1000
    //
    public weak var delegate: ChatUserListDelegate?
    //
    public var isSearchBarVisible = false
    public var isPrefereSmallSize = false
    private var loadingPreviousData: Bool = false
    private var hasLoadedAllData: Bool = false
    private var pageSize: Int = 100
    // MARK: - VIEW CYCLE
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
    }
}
// MARK: - SETUP UI
extension ChatUserListVC {
    //
    private func setupUI() {
        //
        self.setupSearch()
        //
        self.setupTableView()
        //
        self.activityIndicator.hidesWhenStopped = true
        //
        searchBarView.layer.cornerRadius = 20.0
        searchBarContainerView.isHidden = !isSearchBarVisible
        //
        //userListController.delegate = self
    }
    //
    private func setupSearch() {
        self.searchField.autocorrectionType = .no
        self.searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    //
    private func setupTableView() {
        //
        //self.tableView?.removeFromSuperview()
        //let tableViewStyle: UITableView.Style = self.curentSortType == .sortByName ? .grouped : .plain
        //self.tableView = UITableView.init(frame: .zero, style: tableViewStyle)
        //
        tableView?.delegate = self
        tableView?.dataSource = self
        //tableView?.bounces = false
        tableView?.contentInsetAdjustmentBehavior = .never
        tableView?.backgroundView = UIView()
        tableView?.backgroundColor = .clear
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        tableView?.tableFooterView = UIView(frame: frame)
        tableView?.tableHeaderView = UIView(frame: frame)
        tableView?.separatorStyle = .none
        tableView?.backgroundColor = .clear
        tableView?.keyboardDismissMode = .onDrag
        tableView?.estimatedRowHeight = 44.0
        tableView?.rowHeight = UITableView.automaticDimension
        //
        let reuseID = TableViewHeaderChatUserList.reuseId
        let nib = UINib(nibName: reuseID, bundle: nil)
        tableView?.register(nib, forCellReuseIdentifier: reuseID)
        //
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        tableView?.contentInsetAdjustmentBehavior = .never
    }
    public func reloadData() {
        self.tableView?.reloadData()
    }
    //
    private func update(for state: ChatUserLoadingState) {
        //
        self.dataLoadingState = state
        //
        switch state {
        case .error:
            activityIndicator.stopAnimating()
            //
        case .searching,.loading:
            //
            self.lastSeenWiseUserList.removeAll()
            self.nameWiseUserList = []
            self.tableView?.reloadData()
            self.noMatchView.isHidden = true
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            self.tableView?.alpha = 0
            //
        case .noUsers:
            noMatchView.isHidden = false
            activityIndicator.stopAnimating()
            tableView?.alpha = 0
            alertImage.image = Appearance.Images.systemMagnifying
            alertText.text = "No user matches these keywords..."
            //
        case .selected:
            break
        case .completed:
            activityIndicator.stopAnimating()
            let lastItem: Int = self.curentSortType == .sortByName ? self.nameWiseUserList.count : self.lastSeenWiseUserList.count
            if lastItem > 0 {
                noMatchView.isHidden = true
                activityIndicator.stopAnimating()
                tableView?.alpha = 1
            } else {
                noMatchView.isHidden = false
                tableView?.alpha = 0
                if self.searchField.text?.isBlank == false {
                    alertImage.image = Appearance.Images.systemMagnifying
                    alertText.text = "No user matches these keywords..."
                } else {
                    alertImage.image = nil
                    alertText.text = "No chats here yet..."
                }
            }
        }
        //
        self.delegate?.chatListStateUpdated(state: self.dataLoadingState)
    }
}

// MARK: - ACTIONS
public extension ChatUserListVC {
    // Search
    @objc private func textDidChange(_ sender: UITextField) {
        self.searchDataUsing(searchString: sender.text)
    }
    // Public function to get search string from out side this controller
    public func searchDataUsing(searchString: String?) {
        //
        self.update(for: .searching)
        searchOperation?.cancel()
        searchOperation = DispatchWorkItem { [weak self] in
            self?.searchUser(with: searchString)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: searchOperation!)
    }
    
    // Sorting
    public func sortUserWith(type: Em_ChatUserListFilterTypes, filteredUsers: [ChatUser]) {
        self.curentSortType = type
        self.lastSeenWiseUserList.removeAll()
        self.nameWiseUserList = []
        self.tableView?.reloadData()
        //
        DispatchQueue.main.async {
            self.setupTableView()
            //
            switch self.curentSortType {
            case .sortByName:
                self.shortByName(filteredUsers: filteredUsers)
            case .sortByAtoZ:
                self.shortAtoZ(filteredUsers: filteredUsers)
            case .sortByLastSeen:
                self.shortLastSeen(filteredUsers: filteredUsers)
            }
        }
    }
    
    private func shortAtoZ(filteredUsers: [ChatUser]) {
        
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        //
        self.lastSeenWiseUserList = alphabetUsers
        self.lastSeenWiseUserList.append(contentsOf: otherUsers)
        //
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.update(for: .completed)
        }
    }
    private func shortLastSeen(filteredUsers: [ChatUser]) {
        
        let onlineUser = filteredUsers.filter({ $0.isOnline && $0.name?.isBlank == false }).sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let alphabetUsers = onlineUser.filter { ($0.name?.isFirstCharacterAlp ?? false) }
        let nonAphabetUsers = onlineUser.filter { ($0.name?.isFirstCharacterAlp ?? false) == false}
        
        let otherUsers = filteredUsers.filter({ $0.isOnline == false && $0.name?.isBlank == false}).sorted(by: { ($0.lastActiveAt ?? $0.userCreatedAt) > ($1.lastActiveAt ?? $1.userCreatedAt )})
        //
        self.lastSeenWiseUserList.append(contentsOf: alphabetUsers)
        self.lastSeenWiseUserList.append(contentsOf: nonAphabetUsers )
        self.lastSeenWiseUserList.append(contentsOf: otherUsers)
        //
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.update(for: .completed)
        }
    }
    private func shortByName(filteredUsers: [ChatUser]) {
    
        let alphabetUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) && $0.name?.isBlank == false }.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
        let otherUsers = filteredUsers.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
        //
        let groupByName = Dictionary(grouping: alphabetUsers) { (user) -> Substring in
            return user.name!.lowercased().prefix(1)
        }
        //
        let keys = groupByName.keys.sorted()
        //
        keys.forEach { item  in
            self.nameWiseUserList.append(ChatUserListData.init(letter: String(item), users: groupByName[item] ?? []))
        }
        if !otherUsers.isEmpty {
            self.nameWiseUserList.append(ChatUserListData.init(letter: "#", users: otherUsers))
        }
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.update(for: .completed)
        }
    }
}
// MARK: - GET STREAM API
extension ChatUserListVC {
    //
    private func searchUser(with name: String?) {
        if let strName = name, strName.isEmpty == false {
            if strName.containsEmoji  || strName.isBlank {
                Snackbar.show(text: "Please enter valid name")
                self.update(for: .error)
                return
            }
            var newQuery = self.serachListController.query
            newQuery.filter = .and([
                .autocomplete(.name, text: strName),
                .exists(.lastActiveAt),
                .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
            ])
            serachListController.search(query: newQuery) { error in
                if let error = error {
                    // handle error
                    debugPrint(error)
                    DispatchQueue.main.async {
                        self.update(for: .error)
                    }
                } else {
                    let filterData = self.serachListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
                    self.sortUserWith(type: self.curentSortType, filteredUsers: filterData)
                }
            }
        } else {
            self.fetchUserList()
        }
        
    }
    open func fetchUserList() {
        if self.dataLoadingState != .loading {
            update(for: .loading)
        }
        self.searchField.text = nil
        //
        var newQuery = UserListQuery(filter: .and([
            .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""),
        ]), sort: [.init(key: .lastActivityAt, isAscending: false)], pageSize: 99)
        newQuery.pagination = Pagination(pageSize: 99)
        self.userListController = ChatClient.shared.userListController(query: newQuery)
        let previousCount = self.userListController.users.count
        userListController.synchronize { error in
            if let error = error {
                // handle error
                print(error)
                DispatchQueue.main.async {
                    self.update(for: .error)
                }
            } else {
                self.loadingPreviousData = false
                if previousCount == self.userListController.users.count {
                    self.hasLoadedAllData = true
                }
                let filterData = self.userListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
                self.sortUserWith(type: self.curentSortType, filteredUsers: filterData)
            }
        }
    }
    
    open func sortUserList() {
        if let strName = self.searchField.text, strName.isBlank == false {
            let filterData = self.serachListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
            self.sortUserWith(type: self.curentSortType, filteredUsers: filterData)
        } else  {
            let filterData = self.userListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
            self.sortUserWith(type: self.curentSortType, filteredUsers: filterData)
        }
    }
    
    open func loadMoreChannels(tableView: UITableView, forItemAt indexPath: IndexPath) {
        
        if userListController.state != .remoteDataFetched {
            return
        }
        guard let lastVisibleIndexPath = tableView.indexPathsForVisibleRows?.last else {
            return
        }
        var count = 0
        if self.curentSortType == .sortByName {
            count = self.nameWiseUserList[indexPath.section].users.count
        } else {
            count = self.lastSeenWiseUserList.count
        }
        guard indexPath.row == count - 1  else {
            return
        }
        guard !loadingPreviousData else {
            return
        }
        if hasLoadedAllData {
            return
        }
        loadingPreviousData = true
        self.fetchUserList()
    }
}
// MARK: - Chat user controller delegate
extension ChatUserListVC: ChatUserListControllerDelegate {
    //
    public func controller(_ controller: ChatUserListController, didChangeUsers changes: [ListChange<ChatUser>]) {}
    public func controller(_ controller: DataController, didChangeState state: DataController.State) {}
}

// MARK: - TABLE VIEW DELEGATE & DATASOURCE
extension ChatUserListVC: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        if self.curentSortType == .sortByName {
            return self.nameWiseUserList.count
        }
        return 1
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.curentSortType == .sortByName {
            return self.nameWiseUserList[section].users.count
        } else {
            return self.lastSeenWiseUserList.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //
        let reuseID = TableViewCellChatUser.reuseId
        //
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        //
        var user: ChatUser?
        //
        if self.curentSortType == .sortByName {
            user = self.nameWiseUserList[indexPath.section].users[indexPath.row]
        } else {
            user = self.lastSeenWiseUserList[indexPath.row]
        }
        if user == nil {
            return UITableViewCell()
        }
        //
        var accessaryImage: UIImage?
        if selectedUsers.firstIndex(where: { $0.id == user!.id}) != nil {
            accessaryImage = Appearance.default.images.userSelected
        } else {
            accessaryImage = nil
        }
        cell.config(user: user!,
                        selectedImage: accessaryImage,
                        avatarBG: view.tintColor)
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = nil
        if self.existingUsers.map({ $0.id.lowercased()}).contains(user!.id.lowercased()) {
            cell.containerView.alpha = 0.5
        } else {
            cell.containerView.alpha = 1.0
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        //
        var user: ChatUser?
        //
        if self.curentSortType == .sortByName {
            user = self.nameWiseUserList[indexPath.section].users[indexPath.row]
        } else {
            user = self.lastSeenWiseUserList[indexPath.row]
        }
        if self.existingUsers.map({ $0.id.lowercased()}).contains(user!.id.lowercased()) {
            return
        }
        //
        let selectedUserId = user!.id
        let client = ChatClient.shared
        guard let currentUserId = client.currentUserId else {
            return
        }
        //
        switch userSelectionType {
        case .addFriend:
            if let index = selectedUsers.firstIndex(where: { $0.id == user!.id}) {
                self.selectedUsers.remove(at: index)
            } else {
                self.selectedUsers.append(user!)
            }
            
            self.delegate?.chatUserDidSelect()
            tableView.reloadRows(at: [indexPath], with: .fade)
            return
            
        case .group:
            if let index = selectedUsers.firstIndex(where: { $0.id == user!.id}) {
                self.selectedUsers.remove(at: index)
            } else {
                self.selectedUsers.append(user!)
            }
            
            self.delegate?.chatUserDidSelect()
            tableView.reloadRows(at: [indexPath], with: .fade)
            return
        default:
            break
        }
        //
        do {
            let controller = try client
                .channelController(
                    createDirectMessageChannelWith: [selectedUserId, currentUserId],
                    name: nil,
                    imageURL: nil,
                    extraData: [:]
                )
            controller.synchronize { [weak self] error in
                guard let weakSelf = self else {
                    return
                }
                if error == nil {
                    let chatChannelVC = ChatChannelVC()
                    chatChannelVC.channelController = controller
                    if let firstVC = weakSelf.navigationController?.viewControllers.first {
                        NotificationCenter.default.post(name: .hideTabbar, object: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                            guard let self = self else {
                                return
                            }
                            self.navigationController?.setViewControllers([firstVC, chatChannelVC], animated: true)
                        }
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //
        var lastItem: Int?
        //
        if self.curentSortType == .sortByName {
            lastItem = self.nameWiseUserList.count - 1
        } else {
            lastItem = self.lastSeenWiseUserList.count - 1
        }
        if let lastIndex = lastItem, indexPath.row == lastIndex && self.dataLoadingState == .completed {
            //searchController?.loadNextUsers()
        }
        self.loadMoreChannels(tableView: tableView, forItemAt: indexPath)
    }
    //
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.curentSortType == .sortByName {
            guard self.nameWiseUserList.indices.contains(section) else {
                return nil
            }
            //
            let reuseID = TableViewHeaderChatUserList.reuseId
            let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderChatUserList
            header!.lblTitle.text = self.nameWiseUserList[section].letter.capitalized
            header!.titleContainerView.layer.cornerRadius = 12.0
            header!.backgroundColor = .clear
            return header!
        }
        return nil
        //
    }
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        footerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 20)
        return footerView
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.curentSortType == .sortByName {
            return 45
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.curentSortType == .sortByName {
            guard self.nameWiseUserList.indices.contains(section) else {
                return nil
            }
            return self.nameWiseUserList[section].letter.capitalized
        }
        return nil
    }
}

// MARK: - ChatUserListFilterTypes
public enum Em_ChatUserListFilterTypes {
    case sortByLastSeen
    case sortByName
    case sortByAtoZ
    //
    public var getTitle: String {
        switch self {
        case .sortByName: return "SORTED BY NAME"
        case .sortByLastSeen: return "SORTED BY LAST SEEN TIME"
        case .sortByAtoZ: return ""
        }
    }
    public var getSearchQuery: UserListQuery {
        switch self {
        case .sortByName,.sortByAtoZ:
            return UserListQuery(filter: .exists(.id), sort: [.init(key: .name, isAscending: true)])
        case .sortByLastSeen:
            return UserListQuery(filter: .exists(.id), sort: [.init(key: .lastActivityAt, isAscending: false)])
        }
    }
}
// MARK: - Scrollview delegates
extension ChatUserListVC {
    public  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Hide keyboard on scroll
        view.endEditing(true)
    }
}
public extension StringProtocol {
    public  var isFirstCharacterAlp: Bool {
        first?.isASCII == true && first?.isLetter == true
    }
}
