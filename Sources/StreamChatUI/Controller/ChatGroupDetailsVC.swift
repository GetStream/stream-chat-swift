//
//  ChatGroupDetailsVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import UIKit

public class ChatGroupDetailsVC: _ViewController,  AppearanceProvider {
    
    // MARK: - Variables
    var viewModel: ChatGroupDetailViewModel!

    // MARK: - Enums
    enum TableViewSections: Int {
        case profile
        case userList
    }
    
    // MARK: - Outlets
    @IBOutlet weak var heightSafeAreaTop: NSLayoutConstraint!
    @IBOutlet weak var imgMore: StreamChatBackButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var backgroundViews: [UIView]!

    // MARK: - view life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - IB Actions
    @IBAction func btnBackAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnMoreAction(_ sender: Any) {
        
    }
    
    // MARK: - Functions
    private func setupUI() {
        heightSafeAreaTop.constant = UIView.safeAreaTop
        imgMore.setImage(appearance.images.moregreyCircle, for: .normal)
        tableView.register(.init(nibName: "ChannelDetailHeaderTVCell", bundle: nil), forCellReuseIdentifier: "ChannelDetailHeaderTVCell")
        tableView.register(.init(nibName: "TableViewCellChatUser", bundle: nil), forCellReuseIdentifier: "TableViewCellChatUser")
        for view in backgroundViews {
            view.backgroundColor = appearance.colorPalette.groupDetailBackground
        }
    }
}

// MARK: - TableView delegates
extension ChatGroupDetailsVC: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = TableViewSections(rawValue: section) else {
            return 0
        }
        switch section {
        case .profile:
            return 1
        case .userList:
            return 50
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = TableViewSections(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        switch section {
        case .profile:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "ChannelDetailHeaderTVCell",
                for: indexPath) as? ChannelDetailHeaderTVCell,
                  let controller = viewModel.channelController else {
                return UITableViewCell()
            }
            cell.configCell(
                controller: controller,
                screenType: viewModel.screenType)
            return cell
        case .userList:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellChatUser.reuseId,
                for: indexPath) as? TableViewCellChatUser else {
                return UITableViewCell()
            }
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = ChannelMemberCountView.instanceFromNib() else {
            return nil
        }
        view.setParticipantsCount(16)
        return view
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = TableViewSections(rawValue: section) else {
            return 0
        }
        switch section {
        case .profile:
            return 0
        case .userList:
            return 20
        }
    }
}
/*
import Nuke
import StreamChat
import StreamChatUI
import UIKit

public class ChatGroupDetailsVC: ChatBaseVC {
    enum GroupDetailsSection: CaseIterable {
        case userList,attachmentList
    }
    // MARK: - OUTLETS
    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var lblSubtitle: UILabel!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var notificationSwitch: UISwitch!
    @IBOutlet weak var heightSafeareaTop: NSLayoutConstraint!
    var filesContainerView = UIView()
    // MARK: - VARIABLES
    public var groupInviteLink: String?
    public var selectedUsers: [ChatChannelMember] = []
    public var channelController: ChatChannelController?
    private var arrController = [UIViewController]()
    private var usersCount = 0
    private var sectionWiseList = [GroupDetailsSection]()
    private lazy var buttonShowMore: UIButton = {
        let btnShowMore = UIButton(frame: CGRect.init(x: UIScreen.main.bounds.width - 120, y: 0, width: 100, height: 35))
        btnShowMore.setTitle("Show more", for: .normal)
        btnShowMore.setTitleColor(Appearance.default.colorPalette.statusColorBlue, for: .normal)
        btnShowMore.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btnShowMore.addTarget(self, action: #selector(self.showMoreButtonAction(_ :)), for: .touchUpInside)
        return btnShowMore
    }()
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    // MARK: - METHOD
    open func setupUI() {
        heightSafeareaTop.constant = UIView.safeAreaTop
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        let name = self.channelController?.channel?.name ?? ""
        lblTitle.text = name
        self.buttonShowMore.isHidden = true
        self.updateMemberCount()
        sectionWiseList.removeAll()
        tableView.reloadData()
        //
        if let cid = channelController?.cid {
            let controller = ChatClient.shared.memberListController(query: .init(cid: cid))
            controller.synchronize { [weak self] error in
                guard error == nil, let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.selectedUsers = []
                    let nonNilUsers = (controller.members ?? []).filter({ $0.id != nil && $0.name?.isBlank == false })
                    if let ownerUser = nonNilUsers.filter({ $0.memberRole == .owner }).first {
                        weakSelf.selectedUsers.append(ownerUser)
                    }
                    let filteredUsers = nonNilUsers.filter({ $0.memberRole != .owner })
                    let onlineUser = filteredUsers.filter({ $0.isOnline }).sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
                    let offlineUser = filteredUsers.filter({ $0.isOnline == false})
                    let alphabetUsers = offlineUser.filter {($0.name?.isFirstCharacterAlp ?? false) == true && $0.isOnline == false}.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
                    let otherUsers = offlineUser.filter {($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
                    
                    weakSelf.selectedUsers.append(contentsOf: onlineUser)
                    weakSelf.selectedUsers.append(contentsOf: alphabetUsers)
                    weakSelf.selectedUsers.append(contentsOf: otherUsers)
                    weakSelf.updateShowMoreButtonStatus()
                    weakSelf.updateMemberCount()
                    weakSelf.sectionWiseList = GroupDetailsSection.allCases
                    weakSelf.tableView.reloadData()
                }
            }
        }
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        let attchmentID = TableViewCellGroupDetailsAttachmentsList.reuseID
        let attachmentNib = UINib(nibName: attchmentID, bundle: nil)
        tableView.register(attachmentNib, forCellReuseIdentifier: attchmentID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = false
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        tableView.separatorStyle = .none
        notificationSwitch.isOn = !(channelController?.channel?.isMuted ?? true)
    }
    
    private func updateMemberCount() {
        let friendCount = selectedUsers.count
        let onlineUser = selectedUsers.filter( {$0.isOnline}).count ?? 0
        lblSubtitle.text = "\(friendCount) friends, \(onlineUser) online"
    }
    
    private func updateShowMoreButtonStatus() {
        let contentSize = selectedUsers.count * 60
        if CGFloat(contentSize) > (self.tableView.bounds.height - 200) {
            self.buttonShowMore.isHidden = false
            self.usersCount = Int((self.tableView.bounds.height - 200) / 60)
        } else {
            self.buttonShowMore.isHidden = true
            self.usersCount = selectedUsers.count
        }
    }
    
    public func muteNotification() {
        self.channelController?.muteChannel { [weak self] error in
            guard let weakSelf = self else { return }
            let msg = error == nil ? "Notifications muted" : "Error while muted group notifications"
            DispatchQueue.main.async {
                Snackbar.show(text: msg, messageType: StreamChatMessageType.ChatGroupMute)
                weakSelf.notificationSwitch.isOn = false
            }
        }
    }
    
    public func unMuteNotification() {
        self.channelController?.unmuteChannel { [weak self] error in
            guard let weakSelf = self else { return }
            let msg = error == nil ? "Notifications unmuted" : "Error while unmute group notifications"
            DispatchQueue.main.async {
                Snackbar.show(text: msg, messageType: StreamChatMessageType.ChatGroupUnMute)
                weakSelf.notificationSwitch.isOn = true
            }
        }
    }
    // MARK: - ACTIONS
    @IBAction func backBtnTapped(_ sender: UIButton) {
        popWithAnimation()
    }
    
    @IBAction func addFriendButtonAction(_ sender: UIButton) {
        guard let channelVC = self.channelController else { return }
        guard let controller = ChatAddFriendVC
                .instantiateController(storyboard: .GroupChat)  as? ChatAddFriendVC else {
            return
        }
        controller.groupInviteLink = self.groupInviteLink
        controller.channelController = channelVC
        controller.selectionType = .addFriend
        controller.existingUsers = selectedUsers
        controller.bCallbackInviteFriend = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.inviteMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    DispatchQueue.main.async {
                        Snackbar.show(text: "Group invite sent")
                    }
                } else {
                    Snackbar.show(text: "Error while sending invitation link")
                }
            })
        }
        controller.bCallbackAddFriend = { [weak self] users in
            guard let weakSelf = self else { return }
            let ids = users.map{ $0.id}
            weakSelf.channelController?.addMembers(userIds: Set(ids), completion: { error in
                if error == nil {
                    DispatchQueue.main.async {
                        Snackbar.show(text: "Group Member updated")
                        weakSelf.setupUI()
                    }
                } else {
                    Snackbar.show(text: "Error operation could be completed")
                }
            })
        }
        presentPanModal(controller)
    }
    
    @IBAction func notificationToggle(_ sender: UISwitch) {
        if sender.isOn {
            unMuteNotification()
        } else {
            muteNotification()
        }
    }
    
    @objc func showMoreButtonAction(_ sender: UIButton) {
        buttonShowMore.isHidden = true
        let visibleRow = IndexPath.init(row: usersCount, section: 0)
        usersCount = selectedUsers.count
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.tableView.scrollToRow(at: visibleRow, at: .bottom, animated: true)
        }
    }
}

// MARK: - TABLEVIEW
extension ChatGroupDetailsVC: UITableViewDataSource , UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sectionWiseList.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionWiseList[section] {
        case .userList:
            return usersCount
        case .attachmentList:
            return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sectionWiseList[indexPath.section] {
        case .userList:
            let reuseID = TableViewCellChatUser.reuseId
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: reuseID,
                for: indexPath) as? TableViewCellChatUser else {
                return UITableViewCell()
            }
            let user: ChatChannelMember = selectedUsers[indexPath.row]
            cell.configGroupDetails(channelMember: user, selectedImage: nil)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        case .attachmentList:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellGroupDetailsAttachmentsList.reuseID) as? TableViewCellGroupDetailsAttachmentsList else {
                return UITableViewCell.init(frame: .zero)
            }
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.filesContainerView.backgroundColor = Appearance.default.colorPalette.chatViewBackground
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch sectionWiseList[section] {
        case .userList:
            if usersCount == self.selectedUsers.count {
                return nil
            }
            let footerView = UIView()
            footerView.backgroundColor = .clear
            footerView.addSubview(buttonShowMore)
            return footerView
        default:
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch sectionWiseList[section] {
        case .userList:
            if usersCount == self.selectedUsers.count {
                return 0
            }
            return 35
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}

// MARK: - AttachmentType
extension AttachmentType {
    init(tagValue: Int) {
        switch tagValue {
        case 0:
            self.init(rawValue: AttachmentType.image.rawValue)
        case 1:
            self.init(rawValue: AttachmentType.file.rawValue)
        case 2:
            self.init(rawValue: AttachmentType.linkPreview.rawValue)
        default:
            self.init(rawValue: AttachmentType.unknown.rawValue)
        }
    }
}
 */
