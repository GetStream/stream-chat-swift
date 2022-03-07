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
    // MARK: - OUTLETS
    @IBOutlet private var headerView: ChatChannelHeaderView!
    @IBOutlet private var lblTitle: UILabel!
    @IBOutlet private var lblSubtitle: UILabel!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var filesContainerView: UIView!
    @IBOutlet private var buttonMedia: UIButton!
    @IBOutlet private var buttonFiles: UIButton!
    @IBOutlet private var buttonLinks: UIButton!
    @IBOutlet private var notificationSwitch: UISwitch!
    @IBOutlet private var indicatorViewLeadingContraint: NSLayoutConstraint!
    // MARK: - VARIABLES
    public var groupInviteLink: String?
    public var selectedUsers: [ChatChannelMember] = []
    private let scrollViewFiles = UIScrollView()
    private let viewTabIndicator = UIView()
    public var channelController: ChatChannelController?
    private var arrController = [UIViewController]()
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureFilesView()
        ShowAttachement()
    }
    // MARK: - METHOD
    open func setupUI() {
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        let name = self.channelController?.channel?.name ?? ""
        lblTitle.text = name
        self.updateMemberCount()
        //
        if let cid = channelController?.cid {
            let controller = ChatClient.shared.memberListController(query: .init(cid: cid))
            controller.synchronize { [weak self] error in
                guard error == nil, let weakSelf = self else { return }
                DispatchQueue.main.async {
                    weakSelf.selectedUsers =  (controller.members ?? []).filter({ $0.id != nil })
                    weakSelf.tableView.reloadData()
                    weakSelf.updateMemberCount()
                }
            }
        }
        let chatUserID = TableViewCellChatUser.reuseId
        let chatUserNib = UINib(nibName: chatUserID, bundle: nil)
        tableView?.register(chatUserNib, forCellReuseIdentifier: chatUserID)
        tableView.dataSource = self
        tableView.bounces = false
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
    private func ShowAttachement() {
        let arr = self.channelController?.messages.filter({ $0.attachments(payloadType: ImageAttachmentPayload.self).count > 0 }) ?? []
        for subView in  self.scrollViewFiles.subviews {
            guard let attachView = subView as? AttachmentListContainerView else {
                continue
            }
            if let identifier = subView.accessibilityIdentifier , identifier == AttachmentType.image.rawValue {
                attachView.setupChatMessage(arr)
            }
        }
    }
    public func muteNotification() {
        self.channelController?.muteChannel { error in
            let msg = error == nil ? "Notifications muted" : "Error while muted group notifications"
            DispatchQueue.main.async {
                Snackbar.show(text: msg, messageType: StreamChatMessageType.ChatGroupMute)
                self.notificationSwitch.isOn = false
            }
        }
    }
    public func unMuteNotification() {
        self.channelController?.unmuteChannel { error in
            let msg = error == nil ? "Notifications unmuted" : "Error while unmute group notifications"
            DispatchQueue.main.async {
                Snackbar.show(text: msg, messageType: StreamChatMessageType.ChatGroupUnMute)
                self.notificationSwitch.isOn = true
            }
        }
    }
    // MARK: - ACTIONS
    @IBAction func backBtnTapped(_ sender: UIButton) {
        popWithAnimation()
    }
    @IBAction func doneTapped(_ sender: UIButton) { }
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
    @IBAction func mediaButtonAction(_ sender: UIButton) {
        self.scrollToPage(page: 0)
    }
    @IBAction func fileButtonAction(_ sender: UIButton) {
        self.scrollToPage(page: 1)
    }
    @IBAction func linkButtonAction(_ sender: UIButton) {
        self.scrollToPage(page: 2)
    }
    @IBAction func notificationToggle(_ sender: UISwitch) {
        if sender.isOn {
            self.unMuteNotification()
        } else {
            self.muteNotification()
        }
    }
}
// MARK: - Collection View
extension ChatGroupDetailsVC {
    private func configureFilesView() {
        scrollViewFiles.delegate = self
        self.filesContainerView.addSubview(scrollViewFiles)
        scrollViewFiles.frame = filesContainerView.bounds
        var xValue: CGFloat = 0
        let width = UIScreen.main.bounds.width
        
        let arrAttachmentOptions: [AttachmentType] = [.image, .file, .linkPreview]
        for index in 0..<arrAttachmentOptions.count {
            guard let subView: ChatSharedFilesVC = ChatSharedFilesVC
                    .instantiateController(storyboard: .GroupChat) else {
                continue
            }
            xValue = self.scrollViewFiles.frame.size.width * CGFloat(index)
            addChild(subView)
            scrollViewFiles.addSubview(subView.view)
            subView.didMove(toParent: self)
            subView.view.frame = CGRect.init(x: xValue, y: 0, width: width, height: self.filesContainerView.bounds.height)
            subView.attachmentType = arrAttachmentOptions[index]
            subView.setupUI()
        }
        let widthTotal = self.filesContainerView.bounds.size.width * 3
        self.scrollViewFiles.isPagingEnabled = true
        self.scrollViewFiles.contentSize = CGSize(width: widthTotal, height: self.scrollViewFiles.frame.size.height)
    }
    public func scrollToPage(page: Int) {
        var frame: CGRect = self.scrollViewFiles.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.scrollViewFiles.scrollRectToVisible(frame, animated: true)
        self.updateIndicator(page: page)
    }
    public func updateIndicator(page: Int) {
        UIView.animate(withDuration: 0.1) {
            switch page {
            case 0:
                self.indicatorViewLeadingContraint.constant = self.buttonMedia.frame.origin.x
            case 1:
                self.indicatorViewLeadingContraint.constant = self.buttonFiles.frame.origin.x
            case 2:
                self.indicatorViewLeadingContraint.constant = self.buttonLinks.frame.origin.x
            default:
                break
            }
            self.view.layoutIfNeeded()
        }
    }
}
// MARK: - TABLEVIEW
extension ChatGroupDetailsVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedUsers.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseID = TableViewCellChatUser.reuseId
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseID,
            for: indexPath) as? TableViewCellChatUser else {
            return UITableViewCell()
        }
        let user: ChatChannelMember = selectedUsers[indexPath.row]
        cell.configGroupDetails(channelMember: user, selectedImage: nil, avatarBG: view.tintColor)
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = nil
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
// MARK: - UIScrollViewDelegate
extension ChatGroupDetailsVC: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        self.updateIndicator(page: Int(pageNumber))
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
