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
    @IBOutlet private weak var groupImageView: AvatarView!
    @IBOutlet private weak var groupNameLabel: UILabel!
   
    // MARK: - VARIBALES
    public var channelController: ChatChannelController!
    // MARK: - VIEW CYCLE
    public override func viewDidLoad() {
        super.viewDidLoad()
        groupImageView.layer.cornerRadius = groupImageView.bounds.width / 2
        if let imageURL = channelController.channel?.imageURL {
            Nuke.loadImage(with: imageURL, into: groupImageView)
        }
        groupNameLabel.text = channelController.channel!.name!.capitalizingFirstLetter()
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
