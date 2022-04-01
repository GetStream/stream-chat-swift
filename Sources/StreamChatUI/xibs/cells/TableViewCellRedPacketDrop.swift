//
//  TableViewCellRedPacketDrop.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 28/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

class TableViewCellRedPacketDrop: UITableViewCell {
    public static let reuseId: String = "TableViewCellRedPacketDrop"
    public static let nib: UINib = UINib.init(nibName: reuseId, bundle: nil)
    
    // MARK: -  @IBOutlet
    @IBOutlet private weak var viewContainer: UIView!
    @IBOutlet private weak var subContainer: UIView!
    @IBOutlet private weak var sentThumbImageView: UIImageView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var sentCryptoLabel: UILabel!
    @IBOutlet private weak var pickUpButton: UIButton!
    @IBOutlet private weak var lblTotal: UILabel!
    @IBOutlet private weak var lblMax: UILabel!
    @IBOutlet private weak var lblDetails: UILabel!
    @IBOutlet private weak var lblExpire: UILabel!
    @IBOutlet private weak var authorAvatarView: UIImageView!
    @IBOutlet private weak var authorAvatarSpacer: UIView!
    @IBOutlet private weak var authorNameLabel: UILabel!
    @IBOutlet private weak var avatarViewContainerView: UIView!
    @IBOutlet private weak var cellWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var detailsStack: UIStackView!
    @IBOutlet private weak var viewContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var AvatarContainerWidthConstraint: NSLayoutConstraint!
    
    // MARK: -  Variables
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var isSender = false
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }
    
    // MARK: -  View Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        contentView.transform = .mirrorY
        viewContainer.backgroundColor = .clear
        avatarViewContainerView.isHidden = true
        cellWidthConstraint.constant = cellWidth
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: -  Methods
    func configureCell(isSender: Bool) {
        self.isSender = isSender
        // Constraint
        viewContainerTopConstraint.constant = Constants.MessageTopPadding
        viewContainerLeadingConstraint.constant = Constants.MessageLeftPadding
        AvatarContainerWidthConstraint.constant = 0
        // authorAvatarView
        authorAvatarView.contentMode = .scaleAspectFill
        authorAvatarView.layer.cornerRadius = authorAvatarView.bounds.width / 2
        authorAvatarView.backgroundColor = .clear
        // viewContainer
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        // subContainer
        subContainer.backgroundColor = Appearance.default.colorPalette.background6
        subContainer.layer.cornerRadius = 12
        subContainer.clipsToBounds = true
        // sentThumbImageView
        sentThumbImageView.backgroundColor = Appearance.default.colorPalette.background6
        sentThumbImageView.image = Appearance.default.images.redPacketThumb
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.clipsToBounds = true
        // descriptionLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = Appearance.default.colorPalette.redPacketColor
        descriptionLabel.font = Appearance.default.fonts.subheadlineBold.withSize(16)
        descriptionLabel.textAlignment = .left
        // lblTotal
        lblTotal.textAlignment = .center
        lblTotal.numberOfLines = 0
        lblTotal.textColor = .white.withAlphaComponent(0.6)
        lblTotal.font = Appearance.default.fonts.body.withSize(11)
        // lblDetails
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white.withAlphaComponent(0.6)
        lblDetails.font = Appearance.default.fonts.body.withSize(11)
        // lblMax
        lblMax.textAlignment = .center
        lblMax.numberOfLines = 0
        lblMax.textColor = .white.withAlphaComponent(0.6)
        lblMax.font = Appearance.default.fonts.body.withSize(11)
        // lblExpire
        lblExpire.textAlignment = .center
        lblExpire.numberOfLines = 0
        lblExpire.textColor = .white.withAlphaComponent(0.6)
        lblExpire.font = Appearance.default.fonts.body.withSize(11)
        // detailsStack
        detailsStack.axis = .vertical
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 2
        subContainer.addSubview(detailsStack)
        detailsStack.alignment = .leading
        // pickUpButton
        pickUpButton.setTitle("Pick Up", for: .normal)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 20
        pickUpButton.isUserInteractionEnabled = true
        pickUpButton.addTarget(self, action: #selector(btnPickButtonAction), for: .touchUpInside)
        // timestampLabel
        timestampLabel.textAlignment = .right
        timestampLabel.textColor = Appearance.default.colorPalette.subtitleText
        timestampLabel.font = Appearance.default.fonts.footnote
        timestampLabel.textAlignment = isSender ? .right : .left
        // author name
        authorNameLabel.text = content?.author.name ?? ""
        authorNameLabel.textAlignment = .left
        authorNameLabel.textColor = Appearance.default.colorPalette.subtitleText
        authorNameLabel.font = Appearance.default.fonts.footnote
        // Avatar
        let placeholder = Appearance.default.images.userAvatarPlaceholder1
        if let imageURL = content?.author.imageURL {
            Components.default.imageLoader.loadImage(
                into: authorAvatarView,
                url: imageURL,
                imageCDN:  Components.default.imageCDN,
                placeholder: placeholder,
                preferredSize: .avatarThumbnailSize
            )
        } else {
            authorAvatarView.image = placeholder
        }
        // avatarViewContainerView
        avatarViewContainerView.isHidden = true
        if let options = layoutOptions {
            //avatarViewContainerView.isHidden = !options.contains(.avatar)
            authorNameLabel.isHidden = !options.contains(.authorName)
            timestampLabel.isHidden = !options.contains(.timestamp)
        }
        // 
        //cellWidthConstraint.constant = avatarViewContainerView.isHidden ? cellWidth : (cellWidth - avatarViewContainerView.bounds.width)
    }

    func configData() {
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }
        configRedPacket()
    }

    private func configRedPacket() {
        guard let extraData = content?.extraData else {
            return
        }
        descriptionLabel.text = extraData.redPacketTitle
        if let maxOne = extraData.redPacketMaxOne {
            lblTotal.text = "Total: \(maxOne) ONE"
        } else {
            lblTotal.text = "Total: 0 ONE"
        }
        if let minOne = extraData.redPacketMinOne {
            lblMax.text = "Max: \(minOne) ONE"
        } else {
            lblMax.text = "Max: 0 ONE"
        }
        let participants = Int(extraData.redPacketParticipantsCount ?? "0") ?? 0
        if participants <= 1 {
            lblDetails.text = "First user receives 100% of the packet!"
        } else {
            lblDetails.text = "Split randomly between: \(participants) users"
        }
        lblExpire.text = "Expires in \(Constants.redPacketExpireTime) minutes!"
    }

    private func getEndTime() -> Date? {
        let strEndTime = content?.extraData.redPacketEndTime ?? ""
        if let date = ISO8601DateFormatter.redPacketExpirationFormatter.date(from: "\(strEndTime)") {
            return date
        } else {
            return nil
        }
    }

    private func isAllowToPick() -> Bool {
        // check userId
        if content?.isSentByCurrentUser ?? false {
            Snackbar.show(text: "You can not pickup your own packet")
            return false
        } else {
            // check end time
            if let endDate = getEndTime() {
                let minutes = Date().minutesFromCurrentDate(endDate)
                if minutes <= 0 {
                    Snackbar.show(text: "", messageType: StreamChatMessageType.RedPacketExpired)
                    return false
                } else {
                    return true
                }
            } else {
                Snackbar.show(text: "", messageType: StreamChatMessageType.RedPacketExpired)
                return false
            }
        }
    }

    @objc private func btnPickButtonAction() {
        guard isAllowToPick(),
              let extraData = content?.extraData,
              isSender == false else {
            return
        }
        NotificationCenter.default.post(name: .pickUpGiftPacket, object: nil, userInfo: extraData)
    }
}
