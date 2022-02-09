//
//  TableViewCellChatUser.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 07/02/22.
//

import StreamChat
import UIKit
import Nuke
import Lottie

class TableViewCellChatUser: UITableViewCell {

    //
    static let reuseId: String = "TableViewCellChatUser"
    //
    @IBOutlet private var mainStackView: UIStackView! {
        didSet {
            mainStackView.isLayoutMarginsRelativeArrangement = true
        }
    }
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var avatarView: AvatarView!
    @IBOutlet private var accessoryImageView: UIImageView!
    // MARK: - Variables
    private var user: ChatUser?
    //
    // MARK: - Functions
    func config(user: ChatUser, selectedImage: UIImage?, avatarBG: UIColor) {
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: avatarView)
        }
        avatarView.backgroundColor = avatarBG
        nameLabel.text = (user.name ?? user.id).capitalizingFirstLetter()
        //
        descriptionLabel.textColor = ChatColor.DESCRIPTION
        //
        if user.isOnline {
            descriptionLabel.textColor = ChatColor.STATUS
            descriptionLabel.text = "Online"
        } else if let lastActive = user.lastActiveAt {
            descriptionLabel.text = "Last seen: " + DTFormatter.formatter.string(from: lastActive)
        } else {
            descriptionLabel.text = "Never seen"
        }
        accessoryImageView.image = selectedImage
        self.user = user
    }
    //
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    //
}
