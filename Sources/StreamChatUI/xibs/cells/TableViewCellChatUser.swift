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
import SkeletonView

public class TableViewCellChatUser: UITableViewCell {
    public static let reuseId: String = "TableViewCellChatUser"
    // MARK: - OUTLETS
    @IBOutlet public var containerView: UIView!
    @IBOutlet public var nameLabel: UILabel!
    @IBOutlet public var descriptionLabel: UILabel!
    @IBOutlet public var avatarView: AvatarView!
    @IBOutlet public var accessoryImageView: UIImageView!
    @IBOutlet public var lblRole: UILabel!
    // MARK: - Variables
    private var user: ChatUser?
    private let shimmerBackgroundColor = Appearance.default.colorPalette.placeHolderBalanceBG
    private lazy var shimmerGradient = SkeletonGradient(colors: [shimmerBackgroundColor.withAlphaComponent(0.3),shimmerBackgroundColor.withAlphaComponent(0.5), shimmerBackgroundColor.withAlphaComponent(0.3)])
    //MARK: - LIFE CYCEL
    public override func awakeFromNib() {
        super.awakeFromNib()
        lblRole.isHidden = true
        avatarView.layer.cornerRadius = avatarView.bounds.height / 2
        accessoryImageView.layer.cornerRadius = accessoryImageView.bounds.height / 2
        self.containerView.backgroundColor = .clear
        SkeletonAppearance.default.gradient = shimmerGradient
    }
}
// MARK: - Config
extension TableViewCellChatUser {
    public func config(user: ChatUser, selectedImage: UIImage?) {
        if let imageURL = user.imageURL {
            let options = ImageLoadingOptions(
                placeholder: Appearance.default.images.userAvatarPlaceholder4,
                transition: .fadeIn(duration: 0.1),
                failureImage: Appearance.default.images.userAvatarPlaceholder4
            )
            Nuke.loadImage(with: imageURL, options: options, into: avatarView)
        }
        avatarView.backgroundColor = .clear
        nameLabel.setChatTitleColor()
        descriptionLabel.setChatSubtitleBigColor()
        let name = (user.name ?? user.id)
        if name.lowercased() == user.id.lowercased()  {
            let last = user.id.suffix(5)
            let first = user.id.prefix(7)
            nameLabel.text = "\(first)...\(last)".capitalizingFirstLetter()
        } else {
            nameLabel.text = name.capitalizingFirstLetter()
        }
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
        lblRole.text = ""
        lblRole.isHidden = true
        // asigned user
        self.user = user
    }
    
    public func configGroupDetails(channelMember: ChatChannelMember, selectedImage: UIImage?) {
        self.config(user: channelMember, selectedImage: selectedImage)
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
}
//MARK: - SHIMMER EFFECT
extension TableViewCellChatUser {
    public func showShimmer() {
        avatarView.image = UIImage()
        avatarView.backgroundColor = shimmerBackgroundColor
        accessoryImageView.image = nil
        avatarView.showAnimatedGradientSkeleton()
        nameLabel.showAnimatedGradientSkeleton()
        descriptionLabel.showAnimatedGradientSkeleton()
    }
    public func hideShimmer() {
        accessoryImageView.hideSkeleton()
        avatarView.hideSkeleton()
        nameLabel.hideSkeleton()
        descriptionLabel.hideSkeleton()
    }
}
