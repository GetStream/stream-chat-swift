//
//  ChatGroupDetailsVC.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 08/02/22.
//

import UIKit
import StreamChat

extension Notification.Name {
    public static let showWalletQRCode = Notification.Name("kStreamChatShowWalletQRCode")
}

public class ChatGroupDetailsVC: _ViewController,  AppearanceProvider {
    
    // MARK: - Variables
    var viewModel: ChatGroupDetailViewModel!
    @UserDefaultCodable(
        key: SCSettings.Contact.contactList.key,
        defaultValue: nil
    )
    var contacts: [ContactModel]?

    // MARK: - Enums
    enum TableViewSections: Int {
        case profile
        case userList
    }
    
    // MARK: - Outlets
    @IBOutlet weak var heightSafeAreaTop: NSLayoutConstraint!
    @IBOutlet weak var btnMore: StreamChatBackButton!
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
    
    // MARK: - Functions
    private func setupUI() {
        heightSafeAreaTop.constant = UIView.safeAreaTop
        btnMore.setImage(appearance.images.moregreyCircle, for: .normal)
        tableView.register(.init(nibName: "ChannelDetailHeaderTVCell", bundle: nil), forCellReuseIdentifier: "ChannelDetailHeaderTVCell")
        tableView.register(.init(nibName: "TableViewCellChatUser", bundle: nil), forCellReuseIdentifier: "TableViewCellChatUser")
        for view in backgroundViews {
            view.backgroundColor = appearance.colorPalette.groupDetailBackground
        }
        closures()
        addMenuToMoreButton()
    }

    private func closures() {
        viewModel.reloadTable = {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.tableView.reloadData()
            }
        }
    }

    private func popBack() {
        dismiss(animated: true, completion: nil)
        navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: .showTabbar, object: nil)
    }

    private func deleteAndLeaveChannel() {
        guard let channelController = viewModel.channelController,
              let channelId = channelController.channel?.cid else {
                  Snackbar.show(text: "Error when deleting the channel")
            return
        }
        let memberListController = channelController.client.memberListController(query: .init(cid: channelId))
        memberListController.synchronize { error in
            guard error == nil else {
                Snackbar.show(text: "Error when deleting the channel")
                return
            }
            let userIds: [UserId] = memberListController.members.map({ member in
                return member.id
            })
            channelController.removeMembers(userIds: Set(userIds)) { _ in
                channelController.deleteChannel { [weak self] error in
                    guard error == nil, let self = self else {
                        Snackbar.show(text: error?.localizedDescription ?? "")
                        return
                    }
                    Snackbar.show(text: "Channel deleted successfully")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.popBack()
                    }
                }
            }
        }
    }

    private func isDirectMessageChannel() -> Bool {
        if viewModel.channelController?.channel?.isDirectMessageChannel ?? false {
            return true
        } else {
            return false
        }
    }

    private func isUserAdmin() -> Bool {
        guard let channel = viewModel.channelController?.channel else {
            return false
        }
        if channel.membership?.memberRole == .admin || channel.membership?.memberRole == .owner {
            return true
        } else {
            return false
        }
    }

    private func addMenuToMoreButton() {
        if #available(iOS 14, *) {
            btnMore.menu = UIMenu(title: "", image: nil, identifier: nil, options: [], children: menuItems())
            btnMore.showsMenuAsPrimaryAction = true
        }
    }

    private func blockUnblockUser(isBlock: Bool) {
        guard let channelId = self.viewModel.channelController?.channel?.cid,
              let user = self.viewModel.user else {
            return
        }
        let controller = ChatClient.shared.memberController(userId: user.id, in: channelId)
        if isBlock {
            controller.ban { error in
                print(error)
            }
        } else {
            controller.unban { error in
                print(error)
            }
        }
    }

    @available(iOS 13, *)
    private func menuItems() -> [UIAction] {
        let reportAction = UIAction(title: "Report", image: appearance.images.exclamationMarkCircle) { _ in
            print("report action")
        }
        let addContact = UIAction(title: "Add as contact", image: appearance.images.personBadgePlus) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.addToContact()
        }
        let blockUser = UIAction(title: "Block user", image: appearance.images.block) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.blockUnblockUser(isBlock: true)
        }
        let unblockUser = UIAction(title: "Unblock user", image: appearance.images.unblock) {  [weak self] _ in
            guard let self = self else {
                return
            }
            self.blockUnblockUser(isBlock: true)
        }
        let shareContact = UIAction(title: "Share contact", image: appearance.images.personTextRectangle) { _ in
        }
        let nickName = UIAction(title: "Nickname", image: appearance.images.rectanglePencil) { _ in
        }
        if isDirectMessageChannel() {
            return [addContact, reportAction]
        } else if viewModel.screenType == .channelDetail {
            return [reportAction]
        } else if viewModel.screenType == .userdetail {
            var arrActions: [UIAction] = [] // [nickName, shareContact]
            if let contactList = contacts {
                let selectedUser = contactList.filter { $0.walletAddress == viewModel.user?.id }
                if selectedUser.isEmpty {
                    arrActions.append(addContact)
                }
            } else {
                arrActions.append(addContact)
            }
            // TODO: Will uncomment when permission issue resolved
            /*
            if isUserAdmin() {
                if viewModel.user?.isBannedFromChannel ?? false {
                    arrActions.append(unblockUser)
                } else {
                    arrActions.append(blockUser)
                }
            }*/
            arrActions.append(reportAction)
            return arrActions
        } else {
            return []
        }
    }

    private func addToContact() {
        guard viewModel.screenType == .userdetail,
              let member = viewModel.user else {
            return
        }
        if contacts == nil {
            var tempModel = [ContactModel]()
            tempModel.append(ContactModel(name: member.name ?? "",
                                          walletAddress: member.id,
                                          avatar: member.imageURL?.absoluteString,
                                          created: Date(),
                                          updated: Date()))
            contacts = tempModel
            Snackbar.show(text: "Contact added successfully!")
        } else {
            let existingUser = contacts!.filter {$0.walletAddress == member.id}
            if !existingUser.isEmpty {
                return
            }
            contacts!.append(ContactModel(name: member.name ?? "",
                                            walletAddress: member.id,
                                               avatar: member.imageURL?.absoluteString,
                                            created: Date(),
                                            updated: Date()))
            Snackbar.show(text: "Contact added successfully!")
        }
        addMenuToMoreButton()
    }
}

// MARK: - TableView delegates
extension ChatGroupDetailsVC: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.screenType == .channelDetail && isDirectMessageChannel() {
            return 1
        } else if viewModel.screenType == .channelDetail && !isDirectMessageChannel() {
            return 2
        } else if viewModel.screenType == .userdetail {
            return 1
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = TableViewSections(rawValue: section) else {
            return 0
        }
        if section == .profile {
            return 1
        } else if section == .userList {
            if isDirectMessageChannel() || viewModel.screenType == .userdetail {
                return 0
            } else {
                return viewModel.channelMembers.count
            }
        } else {
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
            cell.cellDelegate = self
            cell.configCell(
                controller: controller,
                screenType: viewModel.screenType,
                members: viewModel.chatMemberController?.members.count ?? 0,
                channelMember: viewModel.user)
            return cell
        case .userList:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCellChatUser.reuseId,
                for: indexPath) as? TableViewCellChatUser else {
                      return UITableViewCell()
                  }
            let user: ChatChannelMember = viewModel.channelMembers[indexPath.row]
            cell.configGroupDetails(channelMember: user, selectedImage: nil)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = TableViewSections(rawValue: indexPath.section),
              section == .userList,
              let channelController = viewModel.channelController,
              let controller: ChatGroupDetailsVC = ChatGroupDetailsVC.instantiateController(storyboard: .GroupChat) else {
            return
        }
        let user = viewModel.channelMembers[indexPath.row]
        if user.id == ChatClient.shared.currentUserId {
            return
        }
        controller.viewModel = .init(controller: channelController,
                                     channelMember: user)
        navigationController?.pushViewController(controller, animated: true)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = TableViewSections(rawValue: section), section == .userList else {
            return nil
        }
        guard let view = ChannelMemberCountView.instanceFromNib() else {
            return nil
        }
        view.setParticipantsCount(viewModel.chatMemberController?.members.count ?? 0)
        return view
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = TableViewSections(rawValue: section) else {
            return 1
        }
        switch section {
        case .profile:
            return 1
        case .userList:
            return 20
        }
    }
}

// MARK: - Cell Delegate
extension ChatGroupDetailsVC: ChannelDetailHeaderTVCellDelegate {
    func addFriendAction() {
        guard let channelController = viewModel.channelController else { return }
           guard let controller = ChatAddFriendVC
                   .instantiateController(storyboard: .GroupChat) as? ChatAddFriendVC else {
               return
           }
           do {
               let memberListController = try ChatClient.shared.memberListController(
                query: .init(cid: .init(cid: channelController.channel?.cid.description ?? "")))
               memberListController.synchronize { [weak self] error in
                   guard error == nil, let self = self else {
                       return
                   }
                   controller.channelController = channelController
                   controller.groupInviteLink = channelController.channel?.extraData.joinLink
                   controller.selectionType = .addFriend
                   controller.existingUsers = memberListController.members.shuffled()
                   controller.bCallbackAddFriend = { selectedUser in
                       let selectedUserId: [String] = selectedUser.map { $0.id}
                       channelController.addMembers(userIds: Set(selectedUserId)) { [weak self] error in
                           guard let self = self else {
                               return
                           }
                           if error == nil {
                               Snackbar.show(text: "Member added successfully")
                               self.viewModel.initChannelMembers()
                           } else {
                               Snackbar.show(text: "Error while adding member")
                           }
                       }
                   }
                   self.presentPanModal(controller)
               }
           } catch {
               Snackbar.show(text: "something went wrong!")
           }
    }

    func shareChannelLinkAction() {
        guard let channelController = viewModel.channelController else { return }
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            guard let qrCodeVc: GroupQRCodeVC = GroupQRCodeVC.instantiateController(storyboard: .PrivateGroup) else {
                return
            }
            qrCodeVc.groupName = channelController.channel?.name
            qrCodeVc.modalPresentationStyle = .fullScreen
            if channelController.channel?.type == .dao {
                qrCodeVc.strContent = channelController.channel?.extraData.daoJoinLink
            } else {
                qrCodeVc.strContent = channelController.channel?.extraData.joinLink
            }
            UIApplication.shared.keyWindow?.rootViewController?.present(qrCodeVc, animated: true, completion: nil)
        }
    }

    func leaveChannel() {
        guard let channelController = viewModel.channelController else { return }
        var alertTitle = ""
        if isUserAdmin() {
            alertTitle = "Would you like to delete this channel?\nIt'll be permanently deleted."
        } else {
            alertTitle = "Would you like to leave this channel?"
        }
        let deleteAction = UIAlertAction(title: "Leave Channel", style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            if self.isUserAdmin() {
                self.deleteAndLeaveChannel()
            } else {
                if let userId = ChatClient.shared.currentUserId {
                    channelController.removeMembers(userIds: [userId]) { [weak self] error in
                        guard let self = self else {
                            return
                        }
                        if error == nil {
                            self.popBack()
                        } else {
                            Snackbar.show(text: "Error while removing member")
                        }
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
        }
        let alert = UIAlertController.showAlert(
            title: alertTitle,
            message: nil,
            actions: [deleteAction, cancelAction],
            preferredStyle: .actionSheet)
        present(alert, animated: true, completion: nil)
    }

    func showWalletQRCode() {
        guard let user = viewModel.user else {
            return
        }
        var userInfo = [String: Any]()
        userInfo["walletAddress"] = user.id
        userInfo["name"] = user.name
        NotificationCenter.default.post(name: .showWalletQRCode, object: userInfo)
    }
}
