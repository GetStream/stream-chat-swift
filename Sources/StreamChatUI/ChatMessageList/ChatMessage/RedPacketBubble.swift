//
//  RedPacketExpiredBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 06/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class RedPacketBubble: UITableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var sentCryptoLabel: UILabel!
    public private(set) var pickUpButton: UIButton!
    public private(set) var lblDetails: UILabel!
    private var detailsStack: UIStackView!
    var layoutOptions: ChatMessageLayoutOptions?
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    var cellType: CellType!
    var isSender = false
    var channel: ChatChannel?
    var chatClient: ChatClient?

    //Cell Type
    enum CellType {
        case EXPIRED
        case RECEIVED
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

    func configureCell(isSender: Bool, with type: CellType) {
        cellType = type
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -Constants.MessageTopPadding)
        ])
        if isSender {
            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: cellWidth).isActive = true
            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8).isActive = true
        } else {
            viewContainer.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 8).isActive = true
            viewContainer.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -cellWidth).isActive = true
        }

        subContainer = UIView()
        subContainer.translatesAutoresizingMaskIntoConstraints = false
        subContainer.backgroundColor = Appearance.default.colorPalette.background6
        subContainer.layer.cornerRadius = 12
        subContainer.clipsToBounds = true
        viewContainer.addSubview(subContainer)
        NSLayoutConstraint.activate([
            subContainer.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor, constant: 0),
            subContainer.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            subContainer.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
        ])

        sentThumbImageView = UIImageView()
        sentThumbImageView.backgroundColor = Appearance.default.colorPalette.background6
        if type == .EXPIRED {
            sentThumbImageView.image = Appearance.default.images.expiredPacketThumb
        } else {
            sentThumbImageView.image = Appearance.default.images.cryptoSentThumb
        }
        sentThumbImageView.transform = .mirrorY
        sentThumbImageView.contentMode = .scaleAspectFill
        sentThumbImageView.translatesAutoresizingMaskIntoConstraints = false
        sentThumbImageView.clipsToBounds = true
        subContainer.addSubview(sentThumbImageView)
        NSLayoutConstraint.activate([
            sentThumbImageView.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 0),
            sentThumbImageView.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: 0),
            sentThumbImageView.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: 0),
            sentThumbImageView.heightAnchor.constraint(equalToConstant: 250)
        ])

        descriptionLabel = createDescLabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.bottomAnchor.constraint(equalTo: sentThumbImageView.topAnchor, constant: -8),
        ])
        descriptionLabel.transform = .mirrorY
        descriptionLabel.textAlignment = .center

        lblDetails = createDetailsLabel()
        if type == .EXPIRED {
            descriptionLabel.text = "That was fun! \nWant to go next!?"
        } else if type == .RECEIVED {
            //lblDetails.text = "You just picked up 65 ONE!"
            descriptionLabel.text = "Rad - Top Amount!"
        }

        detailsStack = UIStackView(arrangedSubviews: [lblDetails])
        detailsStack.axis = .vertical
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 2
        subContainer.addSubview(detailsStack)
        detailsStack.transform = .mirrorY
        detailsStack.alignment = .center
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsStack.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            detailsStack.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -10),
            detailsStack.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -10)
        ])

        pickUpButton = UIButton()
        pickUpButton.translatesAutoresizingMaskIntoConstraints = false
        pickUpButton.setTitle("Send Packet", for: .normal)
        pickUpButton.addTarget(self, action: #selector(btnSendPacketAction), for: .touchUpInside)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 20
        subContainer.addSubview(pickUpButton)
        NSLayoutConstraint.activate([
            pickUpButton.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 12),
            pickUpButton.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -12),
            pickUpButton.heightAnchor.constraint(equalToConstant: 40),
            pickUpButton.bottomAnchor.constraint(equalTo: detailsStack.topAnchor, constant: -20),
            pickUpButton.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 20)
        ])
        pickUpButton.transform = .mirrorY


        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        timestampLabel.textAlignment = isSender ? .right : .left
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 15),
        ])
        timestampLabel.transform = .mirrorY
    }

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            timestampLabel.textAlignment = .left
            timestampLabel!.textColor = Appearance.default.colorPalette.subtitleText
            timestampLabel!.font = Appearance.default.fonts.footnote
        }
        return timestampLabel!
    }

    private func createDescLabel() -> UILabel {
        if descriptionLabel == nil {
            descriptionLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            descriptionLabel.textAlignment = .center
            descriptionLabel.numberOfLines = 0
            descriptionLabel.textColor = Appearance.default.colorPalette.redPacketExpired
            descriptionLabel.font = Appearance.default.fonts.subheadlineBold.withSize(16)
        }
        return descriptionLabel
    }

    func createDetailsLabel() -> UILabel {
        let lblDetails = UILabel()
            .withAdjustingFontForContentSizeCategory
            .withBidirectionalLanguagesSupport
            .withoutAutoresizingMaskConstraints
        lblDetails.textAlignment = .center
        lblDetails.numberOfLines = 0
        lblDetails.textColor = .white.withAlphaComponent(0.6)
        lblDetails.font = Appearance.default.fonts.body.withSize(11)
        return lblDetails
    }

    private func createSentCryptoLabel() -> UILabel {
        if sentCryptoLabel == nil {
            sentCryptoLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            sentCryptoLabel.textAlignment = .center
            sentCryptoLabel.numberOfLines = 0
            sentCryptoLabel.textColor = Appearance.default.colorPalette.subtitleText
            sentCryptoLabel.font = Appearance.default.fonts.footnote.withSize(11)
        }
        return sentCryptoLabel
    }

    func configData() {
        var nameAndTimeString: String? = ""
        if let options = layoutOptions {
            if options.contains(.authorName), let name = content?.author.name {
                nameAndTimeString?.append("\(name)   ")
            }
            if options.contains(.timestamp) , let createdAt = content?.createdAt {
                nameAndTimeString?.append("\(dateFormatter.string(from: createdAt))")
            }
        }
        timestampLabel?.text = nameAndTimeString
        if cellType == .RECEIVED {
            configTopAmountCell()
        } else if cellType == .EXPIRED {
            configExpiredCell()
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
        guard let channelId = channel?.cid else { return }
        var userInfo = [String: Any]()
        userInfo["channelId"] = channelId
        NotificationCenter.default.post(name: .sendGiftPacketTapAction, object: nil, userInfo: userInfo)
    }
}
/**
 ["highestAmountUserId": StreamChat.RawJSON.string("b939f923-eabc-4094-99cc-0e4e587091f1"), "highestAmountUserName": StreamChat.RawJSON.string("ajay4"), "receivedAmount": StreamChat.RawJSON.number(1.0), "isTopAmountUser": StreamChat.RawJSON.bool(true), "isExpired": StreamChat.RawJSON.bool(false), "redPacketId": StreamChat.RawJSON.string("b300fb35-89a9-4c92-bc5e-71236c92a085")]
 */
