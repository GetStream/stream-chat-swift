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
        viewContainerTopConstraint.constant = MessageTopPadding
        viewContainerLeadingConstraint.constant = MessageLeftPadding
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
        guard let redPacket = getRedPacketExtraData() else {
            return
        }
        if let title = redPacket["title"] {
            let redPacketTitle = fetchRawData(raw: title) as? String ?? ""
            descriptionLabel.text = redPacketTitle
        }
        if let maxOne = redPacket["maxOne"] {
            let one = fetchRawData(raw: maxOne) as? String ?? "0"
            lblTotal.text = "Total: \(one) ONE"
        } else {
            lblTotal.text = "Total: 0 ONE"
        }
        if let minOne = redPacket["minOne"] {
            let one = fetchRawData(raw: minOne) as? String ?? "0"
            lblMax.text = "Max: \(one) ONE"
        } else {
            lblMax.text = "Max: 0 ONE"
        }
        if let participants = redPacket["participantsCount"] {
            let participantCount = fetchRawData(raw: participants) as? String ?? "0"
            let intParticipants = Int(participantCount) ?? 0
            if intParticipants <= 1 {
                lblDetails.text = "First user receives 100% of the packet!"
            } else {
                lblDetails.text = "Split randomly between: \(intParticipants) users"
            }
        }
//        if let endTime = redPacket["endTime"] {
//            let strEndTime = fetchRawData(raw: endTime) as? String ?? ""
//            let dateFormatter = DateFormatter()
//            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
//            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//            if let date = dateFormatter.date(from: strEndTime) {
//
//            }
//        }
        lblExpire.text = "Expires in 30 minutes!"
    }

    private func getRedPacketExtraData() -> [String: RawJSON]? {
        if let extraData = content?.extraData["redPacketPickup"] {
            switch extraData {
            case .dictionary(let dictionary):
                return dictionary
            default:
                return nil
            }
        } else {
            return nil
        }
    }

    private func getEndTime(raw: [String: RawJSON]?) -> Date? {
        guard let rawData = raw else { return nil }
        if let endTime = rawData ["endTime"] {
            let strEndTime = fetchRawData(raw: endTime) as? String ?? ""
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: "\(strEndTime)") {
                return date
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    private func isAllowToPick() -> Bool {
        guard let redPacket = getRedPacketExtraData() else {
            Snackbar.show(text: "Expired - better luck next time!")
            return false
        }
        // check userId
        if content?.isSentByCurrentUser ?? false {
            Snackbar.show(text: "You can not pickup your own packet")
            return false
        } else {
            // check end time
            if let endDate = getEndTime(raw: redPacket) {
                let minutes = Date().minutesFromCurrentDate(endDate)
                if minutes <= 0 {
                    Snackbar.show(text: "Expired - better luck next time!")
                    return false
                } else {
                    return true
                }
            } else {
                Snackbar.show(text: "Expired - better luck next time!")
                return false
            }
        }
    }

    @objc private func btnPickButtonAction() {
        if isAllowToPick() {
            guard let redPacket = getRedPacketExtraData(), isSender == false else {
                return
            }
            if let packetId = redPacket["packetId"] {
                let redPacketId = fetchRawData(raw: packetId) as? String ?? ""
                var userInfo = [String: Any]()
                userInfo["packetId"] = redPacketId
                NotificationCenter.default.post(name: .pickUpRedPacket, object: nil, userInfo: userInfo)
            }
        }
    }
}
