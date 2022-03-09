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
    func chatUserDidSelect()
}
public class ChatUserListVC: UIViewController {
    public enum ChatUserSelectionType {
        case singleUser, group, privateGroup , addFriend
    }
    public enum HeaderType {
        case createChatHeader, noHeader, alphabetHeader
    }
    // MARK: - @IBOutlet
    @IBOutlet private weak var searchFieldStack: UIStackView!
    @IBOutlet private weak var searchBarContainerView: UIView!
    @IBOutlet private weak var searchBarView: UIView!
    @IBOutlet private weak var daoButton: UIButton!
    @IBOutlet private weak var searchField: UITextField!
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
            self.sectionWiseList.removeAll()
            self.viewModel.sortType = sortType
            if sortType != self.viewModel.sortType {
                self.setupTableView()
            }
        }
    }
    public var userSelectionType = ChatUserSelectionType.singleUser
    public var currentSectionType: ChatUserListVC.HeaderType = .noHeader
    private var sectionWiseList = [ChatUserListData]()
    public weak var delegate: ChatUserListDelegate?
    public var isSearchBarVisible = false
    public var isPreferSmallSize = false
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
        self.updateUI()
        self.setupSearch()
        self.setupTableView()
        searchBarView.layer.cornerRadius = 20.0
        searchBarContainerView.isHidden = !isSearchBarVisible
        // UserListCallback
        self.viewModel.bCallbackDataLoadingStateUpdated = { [weak self] loadingState in
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                weakSelf.updateUI()
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
    
    public func tableViewFrameUpdate() { }
    
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
    
    private func updateUI() {
        noMatchView.isHidden = true
        switch self.viewModel.dataLoadingState {
        case .error,.searchingError:
            self.noMatchView.isHidden = true
        case .searching,.loading:
            self.noMatchView.isHidden = true
            self.tableView?.reloadData()
        case .loadMoreData:
            self.noMatchView.isHidden = true
            break
        case .completed:
            noMatchView.isHidden = true
            let userCount = self.sectionWiseList.filter({ $0.sectionType != .createChatHeader}).filter({$0.users.count > 0 })
            if self.viewModel.searchText != nil && userCount.count == 0 {
                self.sectionWiseList.removeAll()
                noMatchView.isHidden = false
                alertImage.image = Appearance.Images.systemMagnifying
                alertText.text = "No user matches these keywords..."
            }
            self.tableView?.reloadData()
        case .none,.loadMoreData:
            self.noMatchView.isHidden = true
            self.tableView?.reloadData()
        }
    }
}
// MARK: - ACTIONS
public extension ChatUserListVC {
    @objc private func textDidChange(_ sender: UITextField) {
        self.viewModel.searchDataUsing(searchString: sender.text)
    }
    // Sorting
    public func sortUserWith(filteredUsers: [ChatUser]) {
        sectionWiseList.removeAll()
        tableView?.reloadData()
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            switch weakSelf.sortType {
            case .sortByName:
                let data = weakSelf.viewModel.shortByName(filteredUsers: filteredUsers)
                weakSelf.sectionWiseList.append(contentsOf: data)
                if weakSelf.currentSectionType == .createChatHeader {
                    weakSelf.sectionWiseList.insert(ChatUserListData.init(letter: "", sectionType: .createChatHeader), at: 0)
                }
            case .sortByAtoZ:
                let data = weakSelf.viewModel.sortAtoZ(filteredUsers: filteredUsers)
                weakSelf.sectionWiseList.append(data)
            case .sortByLastSeen:
                let data = weakSelf.viewModel.sortLastSeen(filteredUsers: filteredUsers)
                weakSelf.sectionWiseList.append(data)
                if weakSelf.currentSectionType == .createChatHeader {
                    weakSelf.sectionWiseList.insert(ChatUserListData.init(letter: "", sectionType: .createChatHeader), at: 0)
                }
            }
            weakSelf.tableView?.reloadData()
            weakSelf.updateUI()
        }
    }
    // TO DO
    private func updateUserList(list: ChatUserListData) {
        guard self.viewModel.searchText == nil else {
            sectionWiseList.removeAll()
            tableView?.reloadData()
            self.sectionWiseList.append(list)
            tableView?.reloadData()
            return
        }
        if let sectionIndex = sectionWiseList.firstIndex(where: { $0.sectionType == list.sectionType }) {
            var section = sectionWiseList[sectionIndex]
            if section.users.count == list.users.count {
                return
            }
            var indexPathToAdd = [IndexPath]()
            var indexPathToUpdate = [IndexPath]()
            var indexPathToDelete = [IndexPath]()
            for (i,user) in list.users.enumerated() {
                if let index = section.users.firstIndex(where: { $0.id.lowercased() == user.id.lowercased()}) {
                    if i == index {
                    } else {
                        sectionWiseList[sectionIndex].users.insert(user, at: i)
                        indexPathToAdd.append(IndexPath.init(row: i, section: sectionIndex))
                        sectionWiseList[sectionIndex].users.remove(at: index)
                        indexPathToDelete.append(IndexPath.init(row: index, section: sectionIndex))
                    }
                } else {
                    sectionWiseList[sectionIndex].users.append(user)
                    indexPathToAdd.append(IndexPath.init(row: sectionWiseList[sectionIndex].users.count - 1, section: sectionIndex))
                }
            }
            tableView?.beginUpdates()
            tableView?.deleteRows(at: indexPathToDelete, with: .automatic)
            tableView?.insertRows(at: indexPathToAdd, with: .automatic)
            tableView?.reloadRows(at: indexPathToUpdate, with: .automatic)
            tableView?.endUpdates()
        } else {
            sectionWiseList.append(list)
            tableView?.reloadData()
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
        switch self.viewModel.dataLoadingState {
        case .searching,.loading,.none:
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
        default:
            let sectionType = sectionWiseList[indexPath.section].sectionType
            switch sectionType {
            case .createChatHeader:
                let reuseID = TableViewHeaderCreateChat.reuseID
                guard let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderCreateChat else { return UITableViewCell.init(frame: .zero)}
                header.labelSortingType.text = self.sortType.getTitle
                header.backgroundColor = .clear
                header.bCallbackGroupCreate = self.bCallbackGroupCreate
                header.bCallbackGroupSelect = self.bCallbackGroupSelect
                header.bCallbackGroupWeHere = self.bCallbackGroupWeHere
                header.bCallbackGroupJoinViaQR = self.bCallbackGroupJoinViaQR
                header.selectionStyle = .none
                return header
            case .noHeader,.alphabetHeader:
                let reuseID = TableViewCellChatUser.reuseId
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: reuseID, for: indexPath) as? TableViewCellChatUser else {
                    return UITableViewCell()
                }
                cell.hideShimmer()
                var user: ChatUser? = sectionWiseList[indexPath.section].users[indexPath.row]
                if user == nil {
                    return UITableViewCell.init(frame: .zero)
                }
                var accessaryImage: UIImage? = nil
                if self.viewModel.selectedUsers.firstIndex(where: { $0.id == user!.id}) != nil {
                    accessaryImage = Appearance.default.images.userSelected
                }
                cell.config(user: user!,selectedImage: accessaryImage)
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                if self.viewModel.existingUsers.map({ $0.id.lowercased()}).contains(user!.id.lowercased()) {
                    cell.containerView.alpha = 0.5
                } else {
                    cell.containerView.alpha = 1.0
                }
                return cell
            }
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        if let cell = tableView.cellForRow(at: indexPath) as? TableViewCellChatUser {
            let selectionColor = Appearance.default.colorPalette.placeHolderBalanceBG.withAlphaComponent(0.7)
            UIView.animate(withDuration: 0.2, delay: 0, options: []) {
                cell.contentView.backgroundColor = selectionColor
                self.view.layoutIfNeeded()
            } completion: { status in
                cell.contentView.backgroundColor = .clear
            }
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
        case .alphabetHeader:
            guard self.sectionWiseList.indices.contains(section) else {
                return nil
            }
            let reuseID = TableViewHeaderChatUserList.reuseId
            guard let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderChatUserList else { return nil }
            header.lblTitle.text = self.sectionWiseList[section].letter.capitalized
            header.titleContainerView.layer.cornerRadius = 12.0
            header.backgroundColor = .clear
            return header
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
        case .alphabetHeader:
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
        case .alphabetHeader:
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
        case .alphabetHeader:
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
public enum Em_ChatUserListFilterTypes: Hashable {
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
