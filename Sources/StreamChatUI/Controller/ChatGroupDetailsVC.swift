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
        closures()
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
                    Snackbar.show(text: "Group deleted successfully")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        guard let self = self else { return }
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            }
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
}

// MARK: - TableView delegates
extension ChatGroupDetailsVC: UITableViewDelegate, UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        switch viewModel.screenType {
        case .channelDetail:
            return 2
        case .userdetail:
            return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = TableViewSections(rawValue: section) else {
            return 0
        }
        switch viewModel.screenType {
        case .channelDetail:
            switch section {
            case .profile:
                return 1
            case .userList:
                return viewModel.channelMembers.count
            default:
                return 0
            }
        case .userdetail:
            switch section {
            case .profile:
                return 1
            case .userList:
                return 0
            default:
                return 0
            }
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
        if user.memberRole == .admin || user.memberRole == .owner {
            return
        }
        controller.viewModel = .init(controller: channelController,
                                     channelMember: user)
        navigationController?.pushViewController(controller, animated: true)
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = ChannelMemberCountView.instanceFromNib() else {
            return nil
        }
        view.setParticipantsCount(viewModel.chatMemberController?.members.count ?? 0)
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

// MARK: - Cell Delegate
extension ChatGroupDetailsVC: ChannelDetailHeaderTVCellDelegate {
    func addFriendAction() {
        guard let channelController = viewModel.channelController else { return }
           guard let controller = ChatAddFriendVC
                   .instantiateController(storyboard: .GroupChat)  as? ChatAddFriendVC else {
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
            alertTitle = "Would you like to delete this group?\nIt'll be permanently deleted."
        } else {
            alertTitle = "Would you like to leave this group?"
        }
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else {
                return
            }
            if self.isUserAdmin() {
                self.deleteAndLeaveChannel()
            } else {
                if let userId = ChatClient.shared.currentUserId {
                    channelController.removeMembers(userIds: [userId]) { error in
                        if error == nil {
                            self.navigationController?.popToRootViewController(animated: true)
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
