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
        case singleUser, group, privateGroup, addFriend
    }
    public enum HeaderType {
        case emptyData, createChatHeader, noHeader, alphabetHeader, loadingData, pagination
    }
    
    // MARK: - @IBOutlet
    @IBOutlet private weak var containerView: UIView!
    private var tableView: UITableView?
    private let safeDataLoadQueue: DispatchQueue = DispatchQueue.init(label: "ChatListUpdateQueue")

    // MARK: - VARIABLES
    public var viewModel = UserListViewModel(sortType: .sortByLastSeen)
    public var sortType: Em_ChatUserListFilterTypes = .sortByLastSeen {
        didSet {
            self.sectionWiseList.removeAll()
            if sortType != self.viewModel.sortType {
                self.setupTableView()
            }
            self.viewModel.sortType = sortType
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
    public var bCallbackAddFriend: ((ChatUser?) -> Void)?

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
        self.setupTableView()
        self.tableView?.reloadData()
        // UserListCallback
        self.viewModel.bCallbackDataLoadingStateUpdated = { [weak self] loadingState in
            guard let weakSelf = self else { return }
            weakSelf.safeDataLoadQueue.async { [weak self] in
                DispatchQueue.main.async {
                    weakSelf.updateUI()
                }
            }
        }
        self.viewModel.bCallbackDataUserList = { [weak self] users in
            guard let weakSelf = self else { return }
            DispatchQueue.main.async {
                weakSelf.viewModel.filteredUsers = users
            }
        }
    }

    private func setupTableView() {
        addCreateChatHeader()
        tableView?.removeFromSuperview()
        let tableViewStyle: UITableView.Style = self.sortType == .sortByName ? .grouped : .plain
        tableView = UITableView.init(frame: .zero, style: .grouped)
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.contentInsetAdjustmentBehavior = .never
        tableView?.setContentOffset(.zero, animated: false)
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
        tableView?.register(TableViewHeaderAlphabetSection.nib, forHeaderFooterViewReuseIdentifier: TableViewHeaderAlphabetSection.identifier)
        tableView?.register(TableViewCellChatUser.nib, forCellReuseIdentifier: TableViewCellChatUser.reuseId)
        tableView?.register(TableViewHeaderCreateChat.nib, forCellReuseIdentifier: TableViewHeaderCreateChat.reuseID)
        tableView?.register(TableViewCellEmptyChatListData.nib, forCellReuseIdentifier: TableViewCellEmptyChatListData.identifier)
        // adding table view to container view
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIView.safeAreaBottom, right: 0)
        containerView.addSubview(tableView!)
        tableView!.backgroundColor = .clear
        // updating tableview frame
        containerView.updateChildViewContraint(childView: tableView!)
    }
    
    public func reloadData() {
        tableView?.reloadData()
    }
    
    private func updateUI() {
        switch self.viewModel.dataLoadingState {
        case .error:
            sectionWiseList.removeAll()
            addCreateChatHeader()
            tableView?.reloadData()
            break
        case .searchingError:
            sectionWiseList.removeAll()
            tableView?.reloadData()
            break
        case .searching:
            sectionWiseList.removeAll()
            addLoadingDataSection()
            tableView?.reloadData()
            break
        case .loading:
            sectionWiseList.removeAll()
            addCreateChatHeader()
            addLoadingDataSection()
            tableView?.reloadData()
            break
        case .loadMoreData:
            addPaginationSection()
            break
        case .completed:
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else { return }
                // User will add and append from this function
                UIView.performWithoutAnimation {
                    weakSelf.sortUserWith(filteredUsers: weakSelf.viewModel.filteredUsers)
                }
                // Checking user count to show empty view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    let userCount = weakSelf.sectionWiseList.filter({ $0.sectionType != .createChatHeader}).filter({$0.users.count > 0 })
                    if weakSelf.viewModel.searchText != nil && userCount.count == 0 {
                        weakSelf.sectionWiseList.removeAll()
                        weakSelf.hideShowEmptyView(hidden: false)
                        weakSelf.tableView?.reloadData()
                    }
                })
            }
            break
        case .none:
            sectionWiseList.removeAll()
            tableView?.reloadData()
            break
        }
    }
    
    private func hideShowEmptyView(hidden: Bool) {
        let _ = removeSection(sectionType: .emptyData)
        if !hidden {
            sectionWiseList.append(ChatUserListData.init(letter: "", sectionType: .emptyData))
        }
    }
    
    private func addCreateChatHeader() {
        guard currentSectionType == .createChatHeader else {
            return
        }
        guard sectionWiseList.firstIndex(where: { $0.sectionType == .createChatHeader}) == nil else {
            return
        }
        sectionWiseList.insert(ChatUserListData.init(letter: "", sectionType: .createChatHeader), at: 0)
    }
    
    private func addLoadingDataSection() {
        if sectionWiseList.firstIndex(where: { $0.sectionType == .loadingData}) == nil {
            sectionWiseList.append(ChatUserListData.init(letter: "", sectionType: .loadingData))
        }
    }
    
    private func removeSection(sectionType: ChatUserListVC.HeaderType) -> IndexSet? {
        if let index = sectionWiseList.firstIndex(where: { $0.sectionType == sectionType}) {
            sectionWiseList.remove(at: index)
            let sectionIndex = IndexSet.init(integer: index)
            return sectionIndex
        }
        return nil
    }
    
    private func addPaginationSection() {
        if sectionWiseList.firstIndex(where: { $0.sectionType == .pagination}) == nil {
            sectionWiseList.append(ChatUserListData.init(letter: "", sectionType: .pagination))
            tableView?.beginUpdates()
            tableView?.insertSections(IndexSet.init(integer: sectionWiseList.count - 1), with: .none)
            tableView?.endUpdates()
        }
    }
    
    private func removePaginationSection() {
        if let index = sectionWiseList.firstIndex(where: { $0.sectionType == .pagination}) {
            sectionWiseList.remove(at: index)
            tableView?.reloadData()
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
        switch sortType {
        case .sortByName:
            let data = viewModel.shortByName(filteredUsers: filteredUsers)
            for item in data {
                updateUserList(newData: item)
            }
        case .sortByAtoZ:
            let data = self.viewModel.sortAtoZ(filteredUsers: filteredUsers)
            updateUserList(newData: data)
        case .sortByLastSeen:
            let data = self.viewModel.sortLastSeen(filteredUsers: filteredUsers)
            updateUserList(newData: data)
        }
        removePaginationSection()
    }

    private func updateUserList(newData: ChatUserListData) {
        self.tableView?.performBatchUpdates({ [weak self] in
            guard let weakSelf = self else { return }
            if let emptyDataSection = weakSelf.removeSection(sectionType: .emptyData) {
                weakSelf.tableView?.deleteSections(emptyDataSection, with: .none)
            }
            if let loadingSection = weakSelf.removeSection(sectionType: .loadingData) {
                weakSelf.tableView?.deleteSections(loadingSection, with: .none)
            }
            if let paginationSection = weakSelf.removeSection(sectionType: .pagination) {
                weakSelf.tableView?.deleteSections(paginationSection, with: .none)
            }
            if let sectionIndex = weakSelf.sectionWiseList.firstIndex(where: { $0.sectionType == newData.sectionType && $0.letter == newData.letter }) {
                let section = weakSelf.sectionWiseList[sectionIndex]
                if section.sectionType == .createChatHeader {
                    return
                }
                let previousUserList = section.users
                var indexPathToAdd = [IndexPath]()
                for (newUserIndex,newUser) in newData.users.enumerated() {
                    guard previousUserList.firstIndex(where: { $0.id.lowercased() == newUser.id.lowercased()}) == nil else {
                        continue
                    }
                    weakSelf.sectionWiseList[sectionIndex].users.insert(newUser, at: newUserIndex)
                    indexPathToAdd.append(IndexPath.init(row: newUserIndex, section: sectionIndex))
                }
                weakSelf.tableView?.insertRows(at: indexPathToAdd, with: .automatic)
                
            } else {
                weakSelf.sectionWiseList.append(newData)
                weakSelf.tableView?.insertSections(IndexSet.init(integer: weakSelf.sectionWiseList.count-1), with: .none)
            }
        }, completion: nil)
    }
}
// MARK: - TABLE VIEW DELEGATE & DATASOURCE
extension ChatUserListVC: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sectionWiseList.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard sectionWiseList.indices.contains(section) else {
            return 0
        }
        switch sectionWiseList[section].sectionType {
        case .emptyData, .createChatHeader, .pagination:
            return 1
        case .loadingData:
            return 10
        default:
            return sectionWiseList[section].users.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard self.sectionWiseList.indices.contains(indexPath.section) else {
            let cell = UITableViewCell.init(frame: .zero)
            cell.backgroundColor = .clear
            return UITableViewCell.init(frame: .zero)
        }
        let sectionType = sectionWiseList[indexPath.section].sectionType
        switch sectionType {
        case .emptyData:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellEmptyChatListData.identifier,
                for: indexPath) as? TableViewCellEmptyChatListData else {
                    return UITableViewCell()
                }
            cell.backgroundColor = .clear
            cell.selectedBackgroundView = nil
            cell.configureCell()
            return cell
        case .loadingData:
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
        case .createChatHeader:
            let reuseID = TableViewHeaderCreateChat.reuseID
            guard let header = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TableViewHeaderCreateChat else { return UITableViewCell.init(frame: .zero)}
            header.labelSortingType.text = sortType.getTitle
            header.backgroundColor = .clear
            header.bCallbackGroupCreate = bCallbackGroupCreate
            header.bCallbackGroupSelect = bCallbackGroupSelect
            header.bCallbackGroupWeHere = bCallbackGroupWeHere
            header.bCallbackGroupJoinViaQR = bCallbackGroupJoinViaQR
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
            if viewModel.existingUsers.map({ $0.id.lowercased()}).contains(user!.id.lowercased()) {
                cell.containerView.alpha = 0.5
            } else {
                cell.containerView.alpha = 1.0
            }
            return cell
        case .pagination:
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
        guard sectionWiseList.indices.contains(indexPath.section), viewModel.dataLoadingState == .completed else {
            return
        }
        guard self.sectionWiseList[indexPath.section].users.indices.contains(indexPath.row) else {
            return
        }
        switch self.sectionWiseList[indexPath.section].sectionType {
        case .emptyData, .createChatHeader, .pagination, .loadingData:
            return
        default:
            break
        }
        let user: ChatUser = sectionWiseList[indexPath.section].users[indexPath.row]
        if self.viewModel.existingUsers.map({ $0.id.lowercased()}).contains(user.id.lowercased()) {
            return
        }
        let selectedUserId = user.id
        let client = ChatClient.shared
        guard let currentUserId = client.currentUserId else {
            return
        }
        switch userSelectionType {
        case .addFriend:
            self.bCallbackAddFriend?(user)
            return
        case .group:
            if let index = self.viewModel.selectedUsers.firstIndex(where: { $0.id == user.id}) {
                self.viewModel.selectedUsers.remove(at: index)
            } else {
                self.viewModel.selectedUsers.append(user)
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
        guard sectionWiseList.indices.contains(section) else {
            return nil
        }
        switch self.sectionWiseList[section].sectionType {
        case .emptyData, .createChatHeader, .pagination, .noHeader, .loadingData:
            return nil
        case .alphabetHeader:
            guard sectionWiseList.indices.contains(section) else {
                return nil
            }
            guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: TableViewHeaderAlphabetSection.identifier) as? TableViewHeaderAlphabetSection else {
                return nil
            }
            header.lblTitle.text = self.sectionWiseList[section].letter.capitalized
            header.titleContainerView.layer.cornerRadius = 12.0
            header.backgroundColor = .clear
            return header
        }
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard sectionWiseList.indices.contains(section) else {
            return nil
        }
        switch sectionWiseList[section].sectionType {
        case .emptyData, .createChatHeader, .pagination, .noHeader, .loadingData:
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
        guard sectionWiseList.indices.contains(section) else {
            return 0
        }
        switch self.sectionWiseList[section].sectionType {
        case .emptyData, .createChatHeader, .pagination, .noHeader, .loadingData:
            return 0
        case .alphabetHeader:
            return 45
        }
        return 0
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard sectionWiseList.indices.contains(section) else {
            return 0
        }
        guard sectionWiseList.indices.contains(section) else {
            return 0
        }
        switch sectionWiseList[section].sectionType {
        case .emptyData, .createChatHeader, .pagination, .noHeader, .loadingData:
            return 0
        case .alphabetHeader:
            return 20
        }
        return 0
    }

    open func loadMoreChannels(tableView: UITableView, forItemAt indexPath: IndexPath) {
        guard sectionWiseList.indices.contains(indexPath.section) else {
            return
        }
        guard sectionWiseList[indexPath.section].users.indices.contains(indexPath.row) else {
            return
        }
        guard viewModel.dataLoadingState == .completed else {
            return
        }
        let lastSection = sectionWiseList.count - 1
        let lastRow =  sectionWiseList[indexPath.section].users.count - 1
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
