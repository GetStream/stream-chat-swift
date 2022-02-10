//
//  UserCredentialsCell.swift
//  Timeless-wallet
//
//  Created by Ajay Ghodadra on 26/10/21.
//

import StreamChat
import UIKit
//import Nuke
//import Lottie
class AvatarView: UIImageView {
    override func updateConstraints() {
        super.updateConstraints()
        translatesAutoresizingMaskIntoConstraints = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = frame.width / 2.0
        contentMode = .scaleAspectFill
    }
}
//
//class UserCredentialsCell: UITableViewCell {
//
//    // MARK: - Outlets
//    @IBOutlet private var mainStackView: UIStackView! {
//        didSet {
//            mainStackView.isLayoutMarginsRelativeArrangement = true
//        }
//    }
//    @IBOutlet private var nameLabel: UILabel!
//    @IBOutlet private var descriptionLabel: UILabel!
//    @IBOutlet private var avatarView: AvatarView!
//    @IBOutlet private var accessoryImageView: UIImageView!
//
//    // MARK: - Variables
//    private var user: ChatUser?
//
//    // MARK: - Functions
//    func config(user: ChatUser, selectedImage: UIImage?, avatarBG: UIColor) {
//        if let imageURL = user.imageURL {
//            Nuke.loadImage(with: imageURL, into: avatarView)
//        }
//        avatarView.backgroundColor = avatarBG
//        nameLabel.text = user.name ?? user.id
//        //
//        descriptionLabel.textColor = ChatColor.DESCRIPTION_COLOR
//        //
//        if user.isOnline {
//            descriptionLabel.textColor = ChatColor.STATUS_COLOR
//            descriptionLabel.text = "Online"
//        } else if let lastActive = user.lastActiveAt {
//            descriptionLabel.text = "Last seen: " + DTFormatter.formatter.string(from: lastActive)
//        } else {
//            descriptionLabel.text = "Never seen"
//        }
//        accessoryImageView.image = selectedImage
//        self.user = user
//    }
//}


