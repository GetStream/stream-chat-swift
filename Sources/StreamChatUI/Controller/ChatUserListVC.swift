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
    public lazy var userListController: ChatUserListController = {
        return ChatClient.shared.userListController()
    }()
    //
    public var tableView: UITableView?
    //
    //var searchController: ChatUserSearchController?
    public var selectedUsers = [ChatUser]()
    public var userSelectionType = ChatUserSelectionType.singleUser
    //
    public var curentSortType: Em_ChatUserListFilterTypes = .sortByLastSeen
    
    //
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
    
    // MARK: - VIEW CYCLE
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
    }
    //
//    func addSearchController(controller: ChatUserSearchController) {
////        self.searchController = controller
////        self.searchController?.delegate = self
////        self.searchController?.query = self.curentSortType.getSearchQuery
////        //
////        self.update(for: .searching)
////        // Empty initial search to get all users
////        self.searchDataUsing(searchString: nil)
//        //
//        fetchUserList()
//    }
    
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
    }
    //
    private func setupSearch() {
        self.searchField.autocorrectionType = .no
        self.searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    //
    private func setupTableView() {
        //
        self.tableView?.removeFromSuperview()
        let tableViewStyle: UITableView.Style = self.curentSortType == .sortByName ? .grouped : .plain
        self.tableView = UITableView.init(frame: .zero, style: tableViewStyle)
        //
        tableView?.delegate = self
        tableView?.dataSource = self
        //tableView?.bounces = false
        tableView?.contentInsetAdjustmentBehavior = .never
        tableView?.backgroundView = UIView()
        tableView?.backgroundColor = .clear
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView?.tableFooterView = UIView()
        tableView?.separatorStyle = .none
        tableView?.backgroundColor = .clear
        //
        let reuseID = TableViewHeaderChatUserList.reuseId
        let nib = UINib(nibName: reuseID, bundle: nil)
        tableView?.register(nib, forCellReuseIdentifier: reuseID)
        //
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        //
        self.containerView.addSubview(self.tableView!)
        //
        self.tableViewFrameUpdate()
        //
    }
    public func tableViewFrameUpdate() {
        self.view.updateConstraints()
        self.view.layoutIfNeeded()
        tableView?.contentInsetAdjustmentBehavior = .never
        containerView.updateChildViewContraint(childView: tableView)
        self.view.updateConstraints()
        self.view.layoutIfNeeded()
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
        case .searching:
            //
            self.lastSeenWiseUserList.removeAll()
            self.nameWiseUserList = []
            self.tableView?.reloadData()
            self.noMatchView.isHidden = true
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            //viewCreateGroup.isHidden = searchField.hasText || !selectedUserIds.isEmpty
            //self.setupTableView()
            //
            self.tableView?.alpha = 0
            //
        case .noUsers:
            noMatchView.isHidden = false
            activityIndicator.stopAnimating()
            //viewCreateGroup.isHidden = true
            tableView?.alpha = 0
            alertImage.image = Appearance.Images.systemMagnifying
            alertText.text = "No user matches these keywords..."
            //
        case .loading:
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            //
        case .selected:
            break
            //
//            noMatchView.isHidden = false
//            activityIndicator.stopAnimating()
//            viewCreateGroup.isHidden = true
//            tableView.alpha = 0
//            //addPersonButton.setImage(.systemPersonBadge, for: .normal)
//            //infoLabelStackView.isHidden = true
//            alertImage.image = nil
//            alertText.text = "No chats here yet..."
        case .completed:
            //
            activityIndicator.stopAnimating()
            //
            let lastItem: Int = self.curentSortType == .sortByName ? self.nameWiseUserList.count : self.lastSeenWiseUserList.count
            //
            if lastItem > 0 {
                noMatchView.isHidden = true
                activityIndicator.stopAnimating()
                //viewCreateGroup.isHidden = searchField.hasText || !selectedUserIds.isEmpty
                tableView?.alpha = 1
            } else {
                noMatchView.isHidden = false
                //viewCreateGroup.isHidden = true
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
        //
        //self.searchController?.query = self.curentSortType.getSearchQuery
        searchOperation?.cancel()
        searchOperation = DispatchWorkItem { [weak self] in
            self?.fetchUserList(with: searchString)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(throttleTime), execute: searchOperation!)
        
//        searchController?.search(term: searchString) { [weak self] error in
//            guard let weakSelf = self else {
//                return
//            }
//            if error != nil {
//                weakSelf.update(for: .error)
//            }
//        }
    }
    
    // Sorting
    public func sortUserWith(type: Em_ChatUserListFilterTypes) {
        //
        self.curentSortType = type
        //
        //update(for: .searching)
        self.lastSeenWiseUserList.removeAll()
        self.nameWiseUserList = []
        self.tableView?.reloadData()
        //
        DispatchQueue.main.async {
            self.setupTableView()
            //
            switch self.curentSortType {
            case .sortByName:
                self.shortByName()
            case .sortByAtoZ:
                self.shortAtoZ()
            case .sortByLastSeen:
                self.shortLastSeen()
            }
        }
    }
    
    private func shortAtoZ() {
        //
        let sortedArr = self.userListController.users.filter({ $0.name?.isEmpty == false && $0.id.isEmpty == false && $0.id != ChatClient.shared.currentUserId ?? "" })
        //
        let alphabetUsers = sortedArr.filter { ($0.name?.isFirstCharacterAlp ?? false) }
        var otherUsers = sortedArr.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }
        //
        otherUsers.sort { obj1, obj2 in
            if let user1 = obj1.id.first, let user2 = obj2.id.first {
                return user1 < user2
            }
            return false
        }
        
        self.lastSeenWiseUserList = alphabetUsers.sorted(by: { ($0.name ?? "") < ($1.name ?? "" )})
        self.lastSeenWiseUserList.append(contentsOf: otherUsers)
        //
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.update(for: .completed)
        }
    }
    private func shortLastSeen() {
        //
        let sortedArr = self.userListController.users.filter({ $0.name?.isEmpty == false && $0.id.isEmpty == false && $0.id != ChatClient.shared.currentUserId ?? "" })
        //
        let onlineUser = sortedArr.filter({ $0.isOnline })
        let otherUsers = sortedArr.filter({ $0.isOnline == false })
        //
        self.lastSeenWiseUserList = otherUsers.sorted(by: { ($0.lastActiveAt ?? $0.userCreatedAt) > ($1.lastActiveAt ?? $1.userCreatedAt )})
        onlineUser.forEach {self.lastSeenWiseUserList.insert( $0, at: 0)}
        //
//        self.lastSeenWiseUserList.sort(by: { ($0.lastActiveAt ?? $0.userCreatedAt) > ($1.lastActiveAt ?? $1.userCreatedAt )})
        //
        DispatchQueue.main.async {
            self.tableView?.reloadData()
            self.update(for: .completed)
        }
    }
    private func shortByName() {
        //
        let sortedArr = self.userListController.users.filter { $0.name?.isEmpty == false }.filter { $0.id.isEmpty == false }.filter { $0.id != ChatClient.shared.currentUserId ?? "" }
        //
        let alphabetUsers = sortedArr.filter { ($0.name?.isFirstCharacterAlp ?? false) }
        var otherUsers = sortedArr.filter { ($0.name?.isFirstCharacterAlp ?? false) == false }
        //
        otherUsers.sort { obj1, obj2 in
            if let user1 = obj1.id.first, let user2 = obj2.id.first {
                return user1 < user2
            }
            return false
        }
        //
        let groupByName = Dictionary(grouping: alphabetUsers) { (user) -> Substring in
            return user.name!.prefix(1)
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
    open func fetchUserList(with name: String? = nil) {
        
        //
        if self.dataLoadingState != .searching {
            update(for: .searching)
        }
        //
//        let query = UserListQuery.init(filter: .notEqual(.id, to: ChatClient.shared.currentUserId ?? ""), sort: [.init(key: .lastActivityAt, isAscending: false)], pageSize: 60)
//
//        userListController = ChatClient.shared.userListController(query: query)
        //
        self.searchField.text = name
        //
        if let strName = name, strName.isEmpty == false {
            if strName.isAlphabet {
                userListController = ChatClient.shared.userListController(
                    query: .init(filter: .autocomplete(.name, text: strName))
                )
            } else {
                let alert = UIAlertController(title: "", message: "Please enter valid name", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.update(for: .error)
                return
            }
        } else {
            userListController = ChatClient.shared.userListController()
        }
        //
        guard self.dataLoadingState == .searching else {
            return
        }
        //
        userListController.synchronize { error in
            if let error = error {
                // handle error
                print(error)
                DispatchQueue.main.async {
                    self.update(for: .error)
                }
            } else {
                // access users
                print(self.userListController.users.count)
                self.sortUserWith(type: self.curentSortType)
            }
        }
        
        //
        //        // load more if needed
        //        controller.loadNextUsers(limit: 10) { error in
        //            // handle error / access users
        //        }
    }
    
}
// MARK: - Chat user controller delegate
extension ChatUserListVC: ChatUserSearchControllerDelegate {
    //
    public func controller(_ controller: ChatUserSearchController, didChangeUsers changes: [ListChange<ChatUser>]) {
        //
//        if self.curentSortType == .sortByName {
//            self.nameWiseUserList.users.append(contentsOf: changes.map({ $0.item}))
//        } else {
//
//        }
        
        //
//        DispatchQueue.main.async {
//            //self.tableView.beginUpdates()
//            self.lastSeenWiseUserList.removeAll()
//            self.nameWiseUserList = []
//            let sortedArr = self.searchController?.users.filter({ $0.name?.isEmpty == false && $0.id.isEmpty == false }) ?? []
//            //
//            let groupByName = Dictionary(grouping: sortedArr) { (user) -> Substring in
//                return user.name!.prefix(1)
//            }
//            let keys = groupByName.keys.sorted()
//            // map the sorted keys to a struct
//            //
//            keys.forEach { item  in
//                self.lastSeenWiseUserList.append(contentsOf: groupByName[item] ?? [])
//                self.nameWiseUserList.append(ChatUserListData.init(letter: String(item), users: groupByName[item] ?? []))
//            }
//            //
////            for change in changes {
////                switch change {
////                case let .insert(_, index: index):
////                    self.tableView.insertRows(at: [index], with: .automatic)
////                case let .move(_, fromIndex: fromIndex, toIndex: toIndex):
////                    self.tableView.moveRow(at: fromIndex, to: toIndex)
////                case let .update(_, index: index):
////                    self.tableView.reloadRows(at: [index], with: .automatic)
////                case let .remove(_, index: index):
////                    self.tableView.deleteRows(at: [index], with: .automatic)
////                }
////            }
//            self.tableView?.reloadData()
//            self.update(for: .completed)
//            //self.tableView.endUpdates()
//        }
    }

    public func controller(_ controller: DataController, didChangeState state: DataController.State) {
        if case .remoteDataFetched = state {
            update(for: .completed)
        }
    }
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
        //
        var accessaryImage: UIImage?
        if selectedUsers.firstIndex(where: { $0.id == user!.id}) != nil {
            accessaryImage = Appearance.Images.systemCheckMarkCircle
        } else {
            accessaryImage = nil
        }
        cell.config(user: user!,
                        selectedImage: accessaryImage,
                        avatarBG: view.tintColor)
        cell.backgroundColor = .clear
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
            self.tableView?.reloadData()
            return
            
        case .group:
            if selectedUsers.firstIndex(where: { $0.id == user!.id}) == nil {
                self.selectedUsers.append(user!)
                self.delegate?.chatUserDidSelect()
                self.tableView?.reloadData()
            }
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
    }
    //
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //
        if self.curentSortType == .sortByName {
            let reuseID = TableViewHeaderChatUserList.reuseId
            let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderChatUserList
            header!.lblTitle.text = self.nameWiseUserList[section].letter.capitalized
            header!.titleContainerView.layer.cornerRadius = 12.0
            header!.backgroundColor = Appearance.default.colorPalette.viewBackgroundLightBlack
            return header!
        }
        return nil
        //
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.curentSortType == .sortByName {
            return 30
        }
        return 0
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.curentSortType == .sortByName {
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


extension UIView {
    //
    public func updateChildViewContraint(childView: UIView?) {
        childView?.translatesAutoresizingMaskIntoConstraints = false
        childView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        childView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        childView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        childView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    public func updateChildViewInCenter(childView: UIView?, constant: CGFloat = 200) {
        childView?.translatesAutoresizingMaskIntoConstraints = false
        childView?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        childView?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        childView?.widthAnchor.constraint(equalToConstant: constant).isActive = true
//        childView?.leftAnchor.constraint(equalTo: leftAnchor, constant: constant).isActive = true
//        childView?.rightAnchor.constraint(equalTo: rightAnchor, constant: -constant).isActive = true
    }
}

public extension StringProtocol {
    public  var isFirstCharacterAlp: Bool {
        first?.isASCII == true && first?.isLetter == true
    }
}
