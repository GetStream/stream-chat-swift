//
//  RedPacketAmountBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 06/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class RedPacketAmountBubble: UITableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    var options: ChatMessageLayoutOptions?
    var content: ChatMessage?
    var client: ChatClient?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    public var blockExpAction: ((URL) -> Void)?
    private(set) lazy var btnExplore: UIButton = {
        let exploreButton = UIButton()
        exploreButton.addTarget(self, action: #selector(btnTapExploreAction), for: .touchUpInside)
        exploreButton.setTitle("", for: .normal)
        exploreButton.backgroundColor = .clear
        return exploreButton
    }()

    var isSender = false

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

    func configureCell(isSender: Bool) {
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -MessageTopPadding)
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
        
        descriptionLabel = createDescLabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 8),
            descriptionLabel.bottomAnchor.constraint(equalTo: subContainer.bottomAnchor, constant: -8),
        ])
        descriptionLabel.transform = .mirrorY
        descriptionLabel.textAlignment = .left
        
        btnExplore.translatesAutoresizingMaskIntoConstraints = false
        subContainer.insertSubview(btnExplore, aboveSubview: descriptionLabel)

        btnExplore.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor).isActive = true
        btnExplore.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor).isActive = true
        btnExplore.heightAnchor.constraint(equalToConstant: 25).isActive = true
        btnExplore.topAnchor.constraint(equalTo: descriptionLabel.topAnchor).isActive = true

        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        timestampLabel.textAlignment = isSender ? .right : .left
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        timestampLabel.transform = .mirrorY
    }

    @objc func btnTapExploreAction() {
        if let txID = getExtraData()?.txId {
            if let blockExpURL = URL(string: "\(Constants.blockExplorer)\(txID)") {
                blockExpAction?(blockExpURL)
            }
        }
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
            descriptionLabel.textColor = .white
            descriptionLabel.font = .systemFont(ofSize: 17)
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

    func configData() {
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }
        configOtherAmount()
    }

    private func configOtherAmount() {
        guard let extraData = getExtraData() else {
            return
        }
        if let userId = extraData["userId"] {
            let strUserId = fetchRawData(raw: userId) as? String ?? ""
            var descriptionText = ""
            if strUserId == client?.currentUserId ?? "" {
                // I picked up other amount
                descriptionText = "\(getCongrates(extraData)) \nYou just picked up \(getAmount(extraData)) ONE! \n\n🧧Red Packet"

            } else {
                // someone pickup amount
                descriptionText = "\(getCongrates(extraData)) \n\(getUserName(extraData)) just picked up \(getAmount(extraData)) ONE! \n\n🧧Red Packet"
            }
            
            let imageAttachment = NSTextAttachment()
            if #available(iOS 13.0, *) {
                imageAttachment.image = Appearance.default.images.arrowUpRightSquare.withTintColor(.white)
            } else {
                // Fallback on earlier versions
            }
            let fullString = NSMutableAttributedString(string: descriptionText + "  ")
            fullString.append(NSAttributedString(attachment: imageAttachment))
            descriptionLabel.attributedText = fullString
        }
    }

    private func getAmount(_ extraData: [String: RawJSON]?) -> String {
        guard let data = extraData else {
            return ""
        }
        if let receivedAmount = data["receivedAmount"] {
            let amount = fetchRawData(raw: receivedAmount) as? Double ?? 0
            return String(format: "%.1f", amount)
        } else {
            return "\(0)"
        }
    }

    private func getUserName(_ extraData: [String: RawJSON]?) -> String {
        guard let data = extraData else {
            return ""
        }
        if let receivedAmount = data["userName"] {
            let strAmount = fetchRawData(raw: receivedAmount) as? String ?? ""
            return strAmount
        } else {
            return ""
        }
    }

    private func getCongrates(_ extraData: [String: RawJSON]?) -> String {
        guard let data = extraData else {
            return ""
        }
        if let congrates = data["congratsKey"] {
            let strCongrates = fetchRawData(raw: congrates) as? String ?? ""
            return strCongrates
        } else {
            return ""
        }
    }

    private func getExtraData() -> [String: RawJSON]? {
        if let extraData = content?.extraData["RedPacketOtherAmountReceived"] {
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
}
