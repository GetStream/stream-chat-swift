//
//  TableViewCellChatUser.swift
//  Timeless-wallet
//
//  Created by Jitendra Sharma on 07/02/22.
//

import StreamChat
import StreamChatUI
import UIKit
import Nuke

public class TableViewCellChatUser: UITableViewCell {

    //
    public static let reuseId: String = "TableViewCellChatUser"
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
    @IBOutlet public var lblRole: UILabel!
    // MARK: - Variables
    private var user: ChatUser?
    //
    // MARK: - Functions
    public func config(user: ChatUser, selectedImage: UIImage?, avatarBG: UIColor) {
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: avatarView)
        }
        avatarView.backgroundColor = avatarBG
        nameLabel.text = (user.name ?? user.id).capitalizingFirstLetter()
        //
        descriptionLabel.textColor = Appearance.default.colorPalette.subTitleColor
        //
        if user.isOnline {
            descriptionLabel.textColor = Appearance.default.colorPalette.statusColorBlue
            descriptionLabel.text = "Online"
        } else if let lastActive = user.lastActiveAt {
            descriptionLabel.text = "Last seen: " + DTFormatter.formatter.string(from: lastActive)
        } else if let lastActive = user.lastActiveAt {
            descriptionLabel.text = "Last seen: " + DTFormatter.formatter.string(from: lastActive)
        } else {
            descriptionLabel.text = "Never seen"
        }
        accessoryImageView.image = selectedImage
        //
        self.user = user
    }
    
    public func configGroupDetails(channelMember: ChatChannelMember, selectedImage: UIImage?, avatarBG: UIColor) {
        self.config(user: channelMember, selectedImage: selectedImage, avatarBG: avatarBG)
        //
        lblRole.text = ""
        lblRole.isHidden = true
        if channelMember.memberRole == .owner {
            lblRole.text = "Owner"
            lblRole.textColor = Appearance.default.colorPalette.statusColorBlue
            lblRole.isHidden = false
        } else if channelMember.isInvited {
           lblRole.text = "Invited"
           lblRole.textColor = Appearance.default.colorPalette.statusColorBlue
           lblRole.isHidden = false
        }
    }
    
    //
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    //
}
