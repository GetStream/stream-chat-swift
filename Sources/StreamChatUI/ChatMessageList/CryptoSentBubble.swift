//
//  CryptoSentBubble.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 29/10/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class CryptoSentBubble: UITableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var sentCryptoLabel: UILabel!
    public private(set) var blockExplorerButton: UIButton!
    var options: ChatMessageLayoutOptions?
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear

        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            viewContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
            viewContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: cellWidth),
            viewContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8),
        ])

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
        sentThumbImageView.image = Appearance.default.images.cryptoSentThumb
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
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.bottomAnchor.constraint(equalTo: sentThumbImageView.topAnchor, constant: -8),
        ])
        descriptionLabel.transform = .mirrorY

        sentCryptoLabel = createSentCryptoLabel()
        sentCryptoLabel.translatesAutoresizingMaskIntoConstraints = false
        subContainer.addSubview(sentCryptoLabel)
        NSLayoutConstraint.activate([
            sentCryptoLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 4),
            sentCryptoLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            sentCryptoLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -6),
        ])
        sentCryptoLabel.transform = .mirrorY

        blockExplorerButton = UIButton()
        blockExplorerButton.translatesAutoresizingMaskIntoConstraints = false
        blockExplorerButton.setTitle("Block Explorer", for: .normal)
        blockExplorerButton.setTitleColor(.white, for: .normal)
        blockExplorerButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        blockExplorerButton.backgroundColor = Appearance.default.colorPalette.popoverBackground
        blockExplorerButton.clipsToBounds = true
        blockExplorerButton.layer.cornerRadius = 20
        subContainer.addSubview(blockExplorerButton)
        NSLayoutConstraint.activate([
            blockExplorerButton.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 12),
            blockExplorerButton.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -12),
            blockExplorerButton.heightAnchor.constraint(equalToConstant: 40),
            blockExplorerButton.bottomAnchor.constraint(equalTo: sentCryptoLabel.bottomAnchor, constant: -35),
            blockExplorerButton.topAnchor.constraint(equalTo: subContainer.topAnchor, constant: 30)
        ])
        blockExplorerButton.transform = .mirrorY


        timestampLabel = createTimestampLabel()
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.addSubview(timestampLabel)
        NSLayoutConstraint.activate([
            timestampLabel.leadingAnchor.constraint(equalTo: viewContainer.leadingAnchor, constant: 0),
            timestampLabel.trailingAnchor.constraint(equalTo: viewContainer.trailingAnchor, constant: 0),
            timestampLabel.bottomAnchor.constraint(equalTo: subContainer.topAnchor, constant: -8),
            timestampLabel.topAnchor.constraint(equalTo: viewContainer.topAnchor, constant: 0),
            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        timestampLabel.transform = .mirrorY
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private var cellWidth: CGFloat {
        return UIScreen.main.bounds.width * 0.3
    }

    private func createTimestampLabel() -> UILabel {
        if timestampLabel == nil {
            timestampLabel = UILabel()
                .withAdjustingFontForContentSizeCategory
                .withBidirectionalLanguagesSupport
                .withoutAutoresizingMaskConstraints
            timestampLabel.textAlignment = .right
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
            descriptionLabel.textColor = Appearance.default.colorPalette.tappableLinkTint
            descriptionLabel.font = Appearance.default.fonts.subheadlineBold.withSize(16)
        }
        return descriptionLabel
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
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }
        configOneWallet()
//        let walletData = getOneWalletExtraData()
//        let fromUserName = walletData["myName"]
//        descriptionLabel.text = "\(walle)"//"Ajay has sent you crypto"
    }

    private func configOneWallet() {
        guard let walletData = getOneWalletExtraData() else {
            return
        }
        if let fromUserName = walletData["myName"] {
            var userName = fetchRawData(raw: fromUserName) as? String ?? ""
            userName = String(userName.prefix(4))
            descriptionLabel.text = "\(userName) has sent you crypto"
        }
        if let amount = walletData["transferAmount"] {
            let one = fetchRawData(raw: amount) as? Double ?? 0
            sentCryptoLabel.text = "SENT: \(one) ONE"
        }

    }

    private func getOneWalletExtraData() -> [String: RawJSON]? {
        if let extraData = content?.extraData["oneWalletTx"] {
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

    private func fetchRawData(raw: RawJSON) -> Any? {
        switch raw {
        case .number(let double):
            return double
        case .string(let string):
            return string
        case .bool(let bool):
            return bool
        case .dictionary(let dictionary):
            return dictionary
        case .array(let array):
            return array
        case .nil:
            return nil
        @unknown default:
            return nil
        }
    }
}
