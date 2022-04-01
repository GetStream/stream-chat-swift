//
//  TableViewCellWallePayBubbleIncoming.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 25/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

public class TableViewCellWallePayBubbleIncoming: UITableViewCell {
    public static let reuseId: String = "TableViewCellWallePayBubbleIncoming"
    public static let nib: UINib = UINib.init(nibName: reuseId, bundle: nil)
    
    // MARK: -  @IBOutlet
    @IBOutlet private weak var viewContainer: UIView!
    @IBOutlet private weak var subContainer: UIView!
    @IBOutlet private weak var sentThumbImageView: UIImageView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var pickUpButton: UIButton!
    @IBOutlet private weak var lblDetails: UILabel!
    @IBOutlet private weak var authorAvatarView: UIImageView!
    @IBOutlet private weak var authorAvatarSpacer: UIView!
    @IBOutlet private weak var authorNameLabel: UILabel!
    @IBOutlet private weak var avatarViewContainerView: UIView!
    @IBOutlet private weak var cellWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var AvatarContainerWidthConstraint: NSLayoutConstraint!
    
    // MARK: -  Variables
    private var cellWidth: CGFloat {
        return (UIScreen.main.bounds.width * 0.3)
    }
    public var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    var isSender = false
    var channel: ChatChannel?
    var chatClient: ChatClient?
    var client: ChatClient?
    var walletPaymentType: WalletAttachmentPayload.PaymentType = .pay
    
    // MARK: -  View Cycle
    public override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        contentView.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        contentView.transform = .mirrorY
        viewContainer.backgroundColor = .clear
        avatarViewContainerView.isHidden = true
        cellWidthConstraint.constant = cellWidth
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
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
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.clipsToBounds = true
        // lblDetails
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white.withAlphaComponent(0.6)
        lblDetails.font = Appearance.default.fonts.body.withSize(11)
        // timestampLabel
        timestampLabel.textAlignment = .left
        timestampLabel.textColor = Appearance.default.colorPalette.subtitleText
        timestampLabel.font = Appearance.default.fonts.footnote
        // authorNameLabel
        authorNameLabel.text = content?.author.name ?? ""
        authorNameLabel.textAlignment = .left
        authorNameLabel.textColor = Appearance.default.colorPalette.subtitleText
        authorNameLabel.font = Appearance.default.fonts.footnote
        // walletPaymentType
        walletPaymentType = content?.attachments(payloadType: WalletAttachmentPayload.self).first?.paymentType ?? .pay
        if walletPaymentType == .request {
            let payload = content?.attachments(payloadType: WalletAttachmentPayload.self).first
            if isSender  {
                descriptionLabel.text = "Payment Requested"
            } else {
                descriptionLabel.text = "\(requestedUserName(raw: payload?.extraData) ?? "-") Requests Payment"
            }
            if let themeURL = requestedThemeURL(raw: payload?.extraData), let imageUrl = URL(string: themeURL) {
                if imageUrl.pathExtension == "gif" {
                    sentThumbImageView.setGifFromURL(imageUrl)
                } else {
                    Nuke.loadImage(with: themeURL, into: sentThumbImageView)
                }
            }
            lblDetails.text = "REQUEST: \(requestedAmount(raw: payload?.extraData) ?? "0") ONE"
        }
        // pickUpButton
        pickUpButton.setTitle("Pay", for: .normal)
        pickUpButton.addTarget(self, action: #selector(btnSendPacketAction), for: .touchUpInside)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 20
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
    }

    func configTopAmountCell() {
        guard let topAmount = getExtraData(key: "RedPacketTopAmountReceived") else {
            return
        }
        if let receivedAmount = topAmount["receivedAmount"] {
            let dblReceivedAmount = fetchRawData(raw: receivedAmount) as? Double ?? 0
            let strReceivedAmount = String(format: "%.2f", dblReceivedAmount)
            if ChatClient.shared.currentUserId ?? "" == getUserId(raw: topAmount) {
                lblDetails.text = "You just picked up \(strReceivedAmount) ONE!"
            } else {
                lblDetails.text = "\(getUserName(raw: topAmount)) just picked up \(strReceivedAmount) ONE!"
            }
        }
    }

    func configExpiredCell() {
        guard let expiredData = getExtraData(key: "RedPacketExpired") else {
            return
        }
        if let userName = expiredData["highestAmountUserName"] {
            let strUserName = fetchRawData(raw: userName) as? String ?? ""
            lblDetails.text = "\(strUserName) selected the highest amount!"
        }
    }

    private func getUserName(raw: [String: RawJSON]) -> String {
        if let userName = raw["highestAmountUserName"] {
            return fetchRawData(raw: userName) as? String ?? ""
        } else {
            return ""
        }
    }

    private func getUserId(raw: [String: RawJSON]) -> String {
        if let userId = raw["highestAmountUserId"] {
            return fetchRawData(raw: userId) as? String ?? ""
        } else {
            return ""
        }
    }

    private func requestedUserName(raw: [String: RawJSON]?) -> String? {
        guard let extraData = raw else {
            return nil
        }
        if let userId = extraData["recipientName"] {
            return fetchRawData(raw: userId) as? String ?? ""
        } else {
            return nil
        }
    }

    private func requestedThemeURL(raw: [String: RawJSON]?) -> String? {
        guard let extraData = raw else {
            return nil
        }
        if let userId = extraData["paymentTheme"] {
            return fetchRawData(raw: userId) as? String ?? ""
        } else {
            return "https://res.cloudinary.com/timeless/image/upload/v1/app/Wallet/shh.png"
        }
    }

    private func requestedUserId(raw: [String: RawJSON]?) -> String? {
        guard let extraData = raw else {
            return nil
        }
        if let userId = extraData["recipientUserId"] {
            return fetchRawData(raw: userId) as? String
        } else {
            return nil
        }
    }

    private func requestedAmount(raw: [String: RawJSON]?) -> String? {
        guard let extraData = raw else {
            return nil
        }
        if let userId = extraData["transferAmount"] {
            return fetchRawData(raw: userId) as? String
        } else {
            return nil
        }
    }

    private func requestedImageUrl(raw: [String: RawJSON]?) -> String? {
        guard let extraData = raw else {
            return nil
        }
        if let imageUrl = extraData["recipientImageUrl"] {
            return fetchRawData(raw: imageUrl) as? String
        } else {
            return nil
        }
    }

    private func requestedIsPaid(raw: [String: RawJSON]?) -> Bool {
        guard let extraData = raw else {
            return true
        }
        if let imageUrl = extraData["isPaid"] {
            return fetchRawData(raw: imageUrl) as? Bool ?? true
        } else {
            return true
        }
    }

    private func getExtraData(key: String) -> [String: RawJSON]? {
        if let extraData = content?.extraData[key] {
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

    @objc func btnSendPacketAction() {
        if walletPaymentType == .request {
            guard let payload = content?.attachments(payloadType: WalletAttachmentPayload.self).first,
                  requestedIsPaid(raw: payload.extraData) == false else {
                return
            }
            if requestedUserId(raw: payload.extraData) == ChatClient.shared.currentUserId {
                Snackbar.show(text: "You can not send one to your own wallet")
                return
            }
            var userInfo = [String: Any]()
            userInfo["transferAmount"] = requestedAmount(raw: payload.extraData)
            userInfo["recipientName"] = requestedUserName(raw: payload.extraData)
            userInfo["recipientUserId"] = requestedUserId(raw: payload.extraData)
            userInfo["requestedImageUrl"] = requestedImageUrl(raw: payload.extraData)
            NotificationCenter.default.post(name: .payRequestTapAction, object: nil, userInfo: userInfo)
        } else {
            guard let channelId = channel?.cid else { return }
            var userInfo = [String: Any]()
            userInfo["channelId"] = channelId
            NotificationCenter.default.post(name: .sendGiftPacketTapAction, object: nil, userInfo: userInfo)
        }
    }
}
