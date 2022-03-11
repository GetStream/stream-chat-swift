//
//  ShareInviteLinkVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 07/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI
import Nuke

public class ShareInviteLinkVC: UIViewController {
    // MARK: - OUTLEST
    @IBOutlet private weak var groupImageView: ChatChannelAvatarView!
    @IBOutlet private weak var groupNameLabel: UILabel!
    @IBOutlet private weak var joinGroupButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var usersCollectionView: CollectionViewGroupUserList!
    @IBOutlet private weak var acttivityIndicator: UIActivityIndicatorView!
    // MARK: - VARIBALES
    public var channelController: ChatChannelController!
    public var groupInviteLink: String?
    public var selectedUsers = [ChatUser]()
    var callbackSelectedUser: (([ChatUser]) -> Void)?
    private var dispatchGroupSendLink = DispatchGroup()
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        groupImageView.layer.cornerRadius = groupImageView.bounds.width / 2
        groupImageView.content = (channelController.channel, nil)
        groupNameLabel.text = channelController.channel!.name!.capitalizingFirstLetter()
        self.containerView.layer.cornerRadius = 30.0
        self.joinGroupButton.layer.cornerRadius = joinGroupButton.bounds.height/2
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(backgroundViewAction))
        tapGesture.numberOfTapsRequired = 1
        self.backgroundView.addGestureRecognizer(tapGesture)
        closeButton.setImage(Appearance.default.images.closePopup, for: .normal)
        usersCollectionView.selectedUsers = self.selectedUsers
        usersCollectionView.callbackSelectedUser = { [weak self] users in
            guard let weakSelf = self else { return }
            weakSelf.selectedUsers = users
            self?.callbackSelectedUser?(users)
            if users.isEmpty {
                self?.dismiss(animated: true, completion: nil)
            }
        }
        usersCollectionView.isRemovreButtonHidden = false
        usersCollectionView.setupUsers(users: selectedUsers)
        acttivityIndicator.hidesWhenStopped = true
        acttivityIndicator.isHidden = true
    }
    
    @objc func backgroundViewAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareInviteButtonAction(_ sender: UIButton) {
        guard self.selectedUsers.count > 0  else {
            return
        }
        guard let inviteLink = self.groupInviteLink else { return }
        guard let currentUserId = ChatClient.shared.currentUserId else {
            return
        }
        self.view.isUserInteractionEnabled = false
        acttivityIndicator.isHidden = false
        acttivityIndicator.startAnimating()
        for user in selectedUsers {
            do {
                self.dispatchGroupSendLink.enter()
            let controller =  try ChatClient.shared.channelController(createDirectMessageChannelWith: [currentUserId,user.id], extraData: [:])
                controller.synchronize { [weak self] error in
                    guard let weakSelf = self else { return }
                    weakSelf.dispatchGroupSendLink.leave()
                    if error == nil {
                        controller.createNewMessage(text: inviteLink)
                    }
                }
            } catch let error {
                self.dispatchGroupSendLink.leave()
            }
        }
        dispatchGroupSendLink.notify(queue: .main) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.acttivityIndicator.stopAnimating()
            weakSelf.dismiss(animated: true, completion: nil)
        }
    }
}
