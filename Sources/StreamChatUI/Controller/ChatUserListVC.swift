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
import SkeletonView

public struct ChatUserListData {
    let letter: String
    let sectionType: ChatUserListVC.HeaderType
    var users = [ChatUser]()
}
public protocol ChatUserListDelegate: AnyObject {
    func chatListStateUpdated(state: UserListViewModel.ChatUserLoadingState)
    func chatUserDidSelect()
}
public class ChatUserListVC: UIViewController {
    public enum ChatUserSelectionType {
        case singleUser, group, privateGroup , addFriend
    }
    public enum HeaderType {
        case createChatHeader, noHeader, aphabetHeader
    }
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
    private var tableView: UITableView?
    // MARK: - VARIABLES
    public var viewModel = UserListViewModel(sortType: .sortByLastSeen)
    public var sortType: Em_ChatUserListFilterTypes = .sortByLastSeen {
        didSet {
            self.viewModel.sortType = sortType
        }
    }
    public var userSelectionType = ChatUserSelectionType.singleUser
    public var curentSectionType: ChatUserListVC.HeaderType = .noHeader
    private var sectionWiseList = [ChatUserListData]()
    public weak var delegate: ChatUserListDelegate?
    public var isSearchBarVisible = false
    public var isPrefereSmallSize = false
    public var bCallbackGroupCreate: (() -> Void)?
    public var bCallbackGroupSelect: (() -> Void)?
    public var bCallbackGroupWeHere: (() -> Void)?
    public var bCallbackGroupJoinViaQR: (() -> Void)?
    // MARK: - VIEW CYCLE
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}
// MARK: - SETUP UI
extension ChatUserListVC {
    private func setupUI() {
        self.update(for: .none)
        self.setupSearch()
        self.setupTableView()
        self.activityIndicator.hidesWhenStopped = true
        searchBarView.layer.cornerRadius = 20.0
        searchBarContainerView.isHidden = !isSearchBarVisible
        // UserListCallaback
        self.viewModel.bCallbackDataLoadingStateUpdated = { [weak self] loadingState in
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                weakSelf.update(for: loadingState)
            }
        }
        self.viewModel.bCallbackDataUserList = { [weak self] users in
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                weakSelf.sortUserWith(filteredUsers: users)
            }
        }
    }

    private func setupSearch() {
        self.searchField.autocorrectionType = .no
        self.searchField.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }
    
    private func setupTableView() {
        tableView?.removeFromSuperview()
        let tableViewStyle: UITableView.Style = self.sortType == .sortByName ? .grouped : .plain
        tableView = UITableView.init(frame: .zero, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
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
        let reuseID = TableViewHeaderChatUserList.reuseId
        let nib = UINib(nibName: reuseID, bundle: nil)
        tableView?.register(nib, forCellReuseIdentifier: reuseID)
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        let createChatHeader = UINib(nibName: TableViewHeaderCreateChat.reuseID, bundle: nil)
        tableView?.register(createChatHeader, forCellReuseIdentifier: TableViewHeaderCreateChat.reuseID)
        self.containerView.addSubview(tableView!)
        tableView!.backgroundColor = .clear
        containerView.updateChildViewContraint(childView: tableView!)
    }
    
    public func reloadData() {
        self.tableView?.reloadData()
    }
    
    private func update(for state: UserListViewModel.ChatUserLoadingState) {
        self.activityIndicator.isHidden = true
        
        switch self.viewModel.dataLoadingState {
        case .error,.searchingError:
            activityIndicator.stopAnimating()
            self.noMatchView.isHidden = true
        case .searching,.loading:
            sectionWiseList.removeAll()
            self.tableView?.reloadData()
            self.noMatchView.isHidden = true
        case .noUsers:
            noMatchView.isHidden = false
            alertImage.image = Appearance.Images.systemMagnifying
            alertText.text = "No user matches these keywords..."
        case .selected:
            break
        case .completed:
            activityIndicator.stopAnimating()
            noMatchView.isHidden = true
            tableView?.alpha = 1
            self.tableView?.reloadData()
//            let lastItem: Int = self.curentSortType == .sortByName ? self.nameWiseUserList.count : self.lastSeenWiseUserList.count
//            if lastItem > 0 {
//                noMatchView.isHidden = true
//                activityIndicator.stopAnimating()
//                tableView?.alpha = 1
//            } else {
//                noMatchView.isHidden = false
//                tableView?.alpha = 0
//                if self.searchField.text?.isBlank == false {
//                    alertImage.image = Appearance.Images.systemMagnifying
//                    alertText.text = "No user matches these keywords..."
//                } else {
//                    alertImage.image = nil
//                    alertText.text = "No chats here yet..."
//                }
//            }
        case .none:
            self.noMatchView.isHidden = true
            sectionWiseList.removeAll()
            self.tableView?.reloadData()
        }
        self.delegate?.chatListStateUpdated(state: self.viewModel.dataLoadingState)
    }
}
// MARK: - ACTIONS
public extension ChatUserListVC {
    @objc private func textDidChange(_ sender: UITextField) {
        self.viewModel.searchDataUsing(searchString: sender.text)
    }
    
    // Sorting
    public func sortUserWith(filteredUsers: [ChatUser]) {
        self.sortType = viewModel.sortType
        sectionWiseList.removeAll()
        self.tableView?.reloadData()
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.setupTableView()
            switch weakSelf.sortType {
            case .sortByName:
                let data = weakSelf.viewModel.shortByName(filteredUsers: filteredUsers)
                weakSelf.sectionWiseList.append(contentsOf: data)
            case .sortByAtoZ:
                let data = weakSelf.viewModel.shortAtoZ(filteredUsers: filteredUsers)
                weakSelf.sectionWiseList.append(data)
            case .sortByLastSeen:
                let data = weakSelf.viewModel.shortLastSeen(filteredUsers: filteredUsers)
                weakSelf.sectionWiseList.append(data)
            }
            if weakSelf.curentSectionType == .createChatHeader {
                weakSelf.sectionWiseList.insert(ChatUserListData(letter: "", sectionType: .createChatHeader), at: 0)
            }
            weakSelf.tableView?.reloadData()
        }
    }
}
// MARK: - TABLE VIEW DELEGATE & DATASOURCE
extension ChatUserListVC: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        if self.viewModel.dataLoadingState == .searching || self.viewModel.dataLoadingState == .loading || self.viewModel.dataLoadingState == .none {
            return 1
        }
        return sectionWiseList.count
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewModel.dataLoadingState == .searching || self.viewModel.dataLoadingState == .loading || self.viewModel.dataLoadingState == .none {
            return 10
        }
        guard self.sectionWiseList.indices.contains(section) else {
            return 0
        }
        if self.sectionWiseList[section].sectionType == .createChatHeader {
            return 1
        }
        return sectionWiseList[section].users.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.viewModel.dataLoadingState == .searching || self.viewModel.dataLoadingState == .loading || self.viewModel.dataLoadingState == .none {
            let reuseID = TableViewCellChatUser.reuseId
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: reuseID,
                for: indexPath) as? TableViewCellChatUser else {
                return UITableViewCell()
            }
            cell.backgroundColor = .clear
            cell.selectedBackgroundView = nil
            
            cell.showShimmer()
            return cell
        }
        let sectionType = sectionWiseList[indexPath.section].sectionType
        if sectionType == .createChatHeader {
            let reuseID = TableViewHeaderCreateChat.reuseID
            let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderCreateChat
            header?.labelSortingType.text = self.sortType.getTitle
            header!.backgroundColor = .clear
            header!.bCallbackGroupCreate = self.bCallbackGroupCreate
            header!.bCallbackGroupSelect = self.bCallbackGroupSelect
            header!.bCallbackGroupWeHere = self.bCallbackGroupWeHere
            header!.bCallbackGroupJoinViaQR = self.bCallbackGroupJoinViaQR
            return header!
        }
        let reuseID = TableViewCellChatUser.reuseId
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        cell.hideShimmer()
        var user: ChatUser? = sectionWiseList[indexPath.section].users[indexPath.row]
        if user == nil {
            return UITableViewCell()
        }
        var accessaryImage: UIImage?
        if self.viewModel.selectedUsers.firstIndex(where: { $0.id == user!.id}) != nil {
            accessaryImage = Appearance.default.images.userSelected
        } else {
            accessaryImage = nil
        }
        cell.config(user: user!,
                        selectedImage: accessaryImage,
                        avatarBG: view.tintColor)
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = nil
        if self.viewModel.existingUsers.map({ $0.id.lowercased()}).contains(user!.id.lowercased()) {
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
        guard self.sectionWiseList.indices.contains(indexPath.section) else {
            return
        }
        guard self.sectionWiseList[indexPath.section].users.indices.contains(indexPath.row) else {
            return
        }
        guard self.viewModel.dataLoadingState == .completed else {
            return
        }
        var user: ChatUser? = sectionWiseList[indexPath.section].users[indexPath.row]
        if self.viewModel.existingUsers.map({ $0.id.lowercased()}).contains(user!.id.lowercased()) {
            return
        }
        let selectedUserId = user!.id
        let client = ChatClient.shared
        guard let currentUserId = client.currentUserId else {
            return
        }
        switch userSelectionType {
        case .addFriend:
            if let index = self.viewModel.selectedUsers.firstIndex(where: { $0.id == user!.id}) {
                self.viewModel.selectedUsers.remove(at: index)
            } else {
                self.viewModel.selectedUsers.append(user!)
            }
            self.delegate?.chatUserDidSelect()
            tableView.reloadRows(at: [indexPath], with: .fade)
            return
        case .group:
            if let index = self.viewModel.selectedUsers.firstIndex(where: { $0.id == user!.id}) {
                self.viewModel.selectedUsers.remove(at: index)
            } else {
                self.viewModel.selectedUsers.append(user!)
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
            debugPrint(error.localizedDescription)
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.loadMoreChannels(tableView: tableView, forItemAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard self.sectionWiseList.indices.contains(section) else {
            return nil
        }
        switch self.sectionWiseList[section].sectionType {
        case .createChatHeader:
            return nil
        case .noHeader:
            return nil
        case .aphabetHeader:
            guard self.sectionWiseList.indices.contains(section) else {
                return nil
            }
            let reuseID = TableViewHeaderChatUserList.reuseId
            let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderChatUserList
            header!.lblTitle.text = self.sectionWiseList[section].letter.capitalized
            header!.titleContainerView.layer.cornerRadius = 12.0
            header!.backgroundColor = .clear
            return header!
        }
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.viewModel.dataLoadingState == .searching || self.viewModel.dataLoadingState == .loading || self.viewModel.dataLoadingState == .none {
            return nil
        }
        guard self.sectionWiseList.indices.contains(section) else {
            return nil
        }
        switch self.sectionWiseList[section].sectionType {
        case .createChatHeader:
            return nil
        case .noHeader:
            return nil
        case .aphabetHeader:
            let footerView = UIView()
            footerView.backgroundColor = .clear
            footerView.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 20)
            return footerView
        }
        return nil
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.viewModel.dataLoadingState == .searching || self.viewModel.dataLoadingState == .loading || self.viewModel.dataLoadingState == .none {
            return 0
        }
        guard self.sectionWiseList.indices.contains(section) else {
            return 0
        }
        switch self.sectionWiseList[section].sectionType {
        case .createChatHeader:
            return 0
        case .noHeader:
            return 0
        case .aphabetHeader:
            return 45
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.viewModel.dataLoadingState == .searching || self.viewModel.dataLoadingState == .loading || self.viewModel.dataLoadingState == .none {
            return 0
        }
        switch self.sectionWiseList[section].sectionType {
        case .createChatHeader:
            return 0
        case .noHeader:
            return 0
        case .aphabetHeader:
            return 20
        }
        return 0
    }

    open func loadMoreChannels(tableView: UITableView, forItemAt indexPath: IndexPath) {
        guard self.sectionWiseList.indices.contains(indexPath.section) else {
            return
        }
        guard self.sectionWiseList[indexPath.section].users.indices.contains(indexPath.row) else {
            return
        }
        guard self.viewModel.dataLoadingState == .completed else {
            return
        }
        let lastSection = self.sectionWiseList.count - 1
        let lastRow =  self.sectionWiseList[lastSection].users.count - 1
        if indexPath.section == lastSection && indexPath.row == lastRow {
            self.viewModel.fetchUserList(true)
        }
    }
}
// MARK: - ChatUserListFilterTypes
public enum Em_ChatUserListFilterTypes {
    case sortByLastSeen
    case sortByName
    case sortByAtoZ
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
