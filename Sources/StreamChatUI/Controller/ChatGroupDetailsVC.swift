//
//  ChatGroupDetailsVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import Foundation
import Nuke
import StreamChat
import StreamChatUI
import UIKit

public class ChatGroupDetailsVC: ChatBaseVC {
    enum GroupDetailsSection: CaseIterable {
        case userList
    }
    // MARK: - OUTLETS
    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var lblSubtitle: UILabel!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var notificationSwitch: UISwitch!
    // MARK: - VARIABLES
    public var groupInviteLink: String?
    public var channelController: ChatChannelController?
    private var groupMembers: [ChatChannelMember] = []
    private let sectionWiseList = GroupDetailsSection.allCases
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchGroupMembers()
    }
    // MARK: - METHOD
    private func setupUI() {
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        let name = self.channelController?.channel?.name ?? ""
        lblTitle.text = name
        let members = channelController?.channel?.lastActiveMembers ?? []
        self.updateMemberCount(members: members)
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        let attachmentID = TableViewCellGroupDetailsAttachmentsList.reuseID
        let attachmentNib = UINib(nibName: attachmentID, bundle: nil)
        tableView.register(attachmentNib, forCellReuseIdentifier: attachmentID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = false
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.reloadData()
        tableView.separatorStyle = .none
        notificationSwitch.isOn = false
        if let isMuted = channelController?.channel?.isMuted {
            notificationSwitch.isOn = !isMuted
        }
    }
    
    private func fetchGroupMembers() {
        if let cid = channelController?.cid {
            let controller = ChatClient.shared.memberListController(query: .init(cid: cid))
            controller.synchronize { [weak self] error in
                guard error == nil, let weakSelf = self else { return }
                DispatchQueue.main.async {
                    var usersList = [ChatChannelMember]()
                    let nonNilUsers = (controller.members ?? []).filter({ $0.id != nil && $0.name?.isBlank == false })
                    if let ownerUser = nonNilUsers.filter({ $0.memberRole == .owner }).first {
                        usersList.append(ownerUser)
                    }
                    let filteredUsers = nonNilUsers.filter({ $0.memberRole != .owner })
                    let onlineUser = filteredUsers.filter({ $0.isOnline }).sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
                    let offlineUser = filteredUsers.filter({ $0.isOnline == false})
                    let alphabetUsers = offlineUser.filter {($0.name?.isFirstCharacterAlp ?? false) == true && $0.isOnline == false}.sorted{ $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending}
                    let otherUsers = offlineUser.filter {($0.name?.isFirstCharacterAlp ?? false) == false }.sorted{ $0.id.localizedCaseInsensitiveCompare($1.id) == ComparisonResult.orderedAscending}
                    // Adding filtered list to user list array
                    usersList.append(contentsOf: onlineUser)
                    usersList.append(contentsOf: alphabetUsers)
                    usersList.append(contentsOf: otherUsers)
                    weakSelf.updateMemberCount(members: usersList)
                    weakSelf.updateFilteredUserList(list: usersList)
                }
            }
        }
    }
    
    private func updateMemberCount(members: [ChatChannelMember]) {
        let friendCount = members.count
        let onlineUser = members.filter( {$0.isOnline}).count ?? 0
        lblSubtitle.text = "\(friendCount) friends, \(onlineUser) online"
    }
    
    private func updateFilteredUserList(list: [ChatChannelMember]) {
        var indexPathForInsert = [IndexPath]()
        var indexPathForDelete = [IndexPath]()
        for (userIndex,user) in list.enumerated() {
            if let oldUserIndex = groupMembers.firstIndex(where: { $0.id.lowercased() == user.id.lowercased() }) {
                if oldUserIndex != userIndex {
                    groupMembers.remove(at: oldUserIndex)
                    indexPathForDelete.append(IndexPath.init(row: oldUserIndex, section: 0))
                    groupMembers.insert(user, at: userIndex)
                    indexPathForInsert.append(IndexPath.init(row: userIndex, section: 0))
                }
            } else {
                groupMembers.insert(user, at: userIndex)
                indexPathForInsert.append(IndexPath.init(row: userIndex, section: 0))
            }
        }
        tableView.beginUpdates()
        tableView.deleteRows(at: indexPathForDelete, with: .automatic)
        tableView.insertRows(at: indexPathForInsert, with: .automatic)
        tableView.endUpdates()
    }
    
    private func muteNotification() {
        self.channelController?.muteChannel { [weak self] error in
            guard let weakSelf = self else { return }
            let msg = error == nil ? "Notifications muted" : "Error while muted group notifications"
            DispatchQueue.main.async {
                Snackbar.show(text: msg, messageType: StreamChatMessageType.ChatGroupMute)
                weakSelf.notificationSwitch.isOn = false
            }
        }
    }
    
    private func unMuteNotification() {
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
        controller.existingUsers = groupMembers
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
                        weakSelf.fetchGroupMembers()
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
}

// MARK: - TABLEVIEW
extension ChatGroupDetailsVC: UITableViewDataSource , UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sectionWiseList.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionWiseList[section] {
        case .userList:
            return groupMembers.count
        default:
            return 0
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
            let user: ChatChannelMember = groupMembers[indexPath.row]
            cell.configGroupDetails(channelMember: user, selectedImage: nil)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        default:
            return UITableViewCell.init(frame: .zero)
        }
    }
}

