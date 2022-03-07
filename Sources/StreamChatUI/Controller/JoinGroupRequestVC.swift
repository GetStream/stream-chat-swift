//
//  JoinGroupRequestVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 05/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI
import Nuke

public class JoinGroupRequestVC: UIViewController {
    // MARK: - OUTLEST
    @IBOutlet private weak var groupImageView: ChatChannelAvatarView!
    @IBOutlet private weak var groupNameLabel: UILabel!
    @IBOutlet private weak var joinGroupButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var usersCollectionView: CollectionViewGroupUserList!
    // MARK: - VARIBALES
    public var channelController: ChatChannelController!
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
        
        let users = channelController.channel?.lastActiveMembers as? [ChatUser] ?? []
        usersCollectionView.setupUsers(users: users)
        if users.isEmpty {
            usersCollectionView.isHidden = true
        }
    }
    @objc func backgroundViewAction() {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func closeButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func joinGroupButtonAction(_ sender: UIButton) {
        channelController.addMembers(userIds: [ChatClient.shared.currentUserId!]) { error in
            guard error == nil else {
                Snackbar.show(text: "Something went wrong!")
                return
            }
            Snackbar.show(text: "Group joined successfully")
            self.dismiss(animated: true, completion: nil)
        }
    }
}
