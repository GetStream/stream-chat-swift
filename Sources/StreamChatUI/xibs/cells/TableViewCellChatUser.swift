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
    let simmerBackgroundColor = Appearance.default.colorPalette.placeHolderBalanceBG.withAlphaComponent(0.9)
    lazy var gradient = SkeletonGradient(colors: [UIColor.clear,simmerBackgroundColor,UIColor.clear])
    //MARK: - LIFE CYCEL
    public override func awakeFromNib() {
        super.awakeFromNib()
        lblRole.isHidden = true
        avatarView.layer.cornerRadius = avatarView.bounds.height / 2
        accessoryImageView.layer.cornerRadius = accessoryImageView.bounds.height / 2
        self.containerView.backgroundColor = .clear
    }
    //    public override func setSelected(_ selected: Bool, animated: Bool) {
    //        super.setSelected(selected, animated: animated)
    //
    //        if self.selectedBackgroundView == nil {
    //            let bgView = UIView()
    //            self.selectedBackgroundView = bgView
    //        }
    //        self.selectedBackgroundView?.backgroundColor = selected ? UIColor.lightGray.withAlphaComponent(0.1) : UIColor.clear
    //    }
    //
    //    public override func setHighlighted(_ highlighted: Bool, animated: Bool) {
    //        super.setHighlighted(highlighted, animated: animated)
    //        if self.selectedBackgroundView == nil {
    //            let bgView = UIView()
    //            self.selectedBackgroundView = bgView
    //        }
    //        self.selectedBackgroundView?.backgroundColor = highlighted ? UIColor.lightGray.withAlphaComponent(0.1) : UIColor.clear
    //    }
}
// MARK: - Config
extension TableViewCellChatUser {
    public func config(user: ChatUser, selectedImage: UIImage?, avatarBG: UIColor) {
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: avatarView)
        }
        //avatarView.backgroundColor = avatarBG
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
}
//MARK: - SHIMMER EFFECT
extension TableViewCellChatUser {
    public func showShimmer() {
        avatarView.image = nil
        avatarView.backgroundColor = simmerBackgroundColor
        accessoryImageView.image = nil
//        avatarView.showGradientSkeleton(usingGradient: gradient, transition: .none)
//        nameLabel.showGradientSkeleton(usingGradient: gradient, transition: .none)
//        descriptionLabel.showGradientSkeleton(usingGradient: gradient, transition: .none)
        avatarView.showSkeleton()
        nameLabel.showSkeleton()
        descriptionLabel.showSkeleton()
    }
    public func hideShimmer() {
        accessoryImageView.hideSkeleton()
        avatarView.hideSkeleton()
        nameLabel.hideSkeleton()
        descriptionLabel.hideSkeleton()
    }
}
