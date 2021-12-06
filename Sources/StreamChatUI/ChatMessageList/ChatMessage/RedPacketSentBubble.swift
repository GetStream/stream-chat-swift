//
//  RedPacketSentBubble.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 03/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class RedPacketSentBubble: UITableViewCell {

    public private(set) var viewContainer: UIView!
    public private(set) var subContainer: UIView!
    public private(set) var sentThumbImageView: UIImageView!
    public private(set) var timestampLabel: UILabel!
    public private(set) var descriptionLabel: UILabel!
    public private(set) var sentCryptoLabel: UILabel!
    public private(set) var pickUpButton: UIButton!
    public private(set) var lblTotal: UILabel!
    public private(set) var lblMax: UILabel!
    public private(set) var lblDetails: UILabel!
    public private(set) var lblExpire: UILabel!
    private var detailsStack: UIStackView!
    var options: ChatMessageLayoutOptions?
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configureCell(isSender: Bool) {
        viewContainer = UIView()
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = .clear
        viewContainer.clipsToBounds = true
        contentView.addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4),
            viewContainer.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4)
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
            descriptionLabel.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            descriptionLabel.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -4),
            descriptionLabel.bottomAnchor.constraint(equalTo: sentThumbImageView.topAnchor, constant: -8),
        ])
        descriptionLabel.transform = .mirrorY
        descriptionLabel.text = "Red Packet Drop!"
        descriptionLabel.textAlignment = .left

        lblTotal = createDetailsLabel()
        lblTotal.text = "Total: 100 ONE"
        lblMax = createDetailsLabel()
        lblMax.text = "Max: 65 ONE"
        lblDetails = createDetailsLabel()
        lblDetails.text = "First user receives 100% of the packet!"
        lblExpire = createDetailsLabel()
        lblExpire.text = "Expires in 10 minutes!"

        detailsStack = UIStackView(arrangedSubviews: [lblTotal, lblMax, lblDetails, lblExpire])
        detailsStack.axis = .vertical
        detailsStack.distribution = .fillEqually
        detailsStack.spacing = 2
        subContainer.addSubview(detailsStack)
        detailsStack.transform = .mirrorY
        detailsStack.alignment = .leading
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailsStack.leadingAnchor.constraint(equalTo: subContainer.leadingAnchor, constant: 10),
            detailsStack.trailingAnchor.constraint(equalTo: subContainer.trailingAnchor, constant: -10),
            detailsStack.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -10)
        ])

        pickUpButton = UIButton()
        pickUpButton.translatesAutoresizingMaskIntoConstraints = false
        pickUpButton.setTitle("Pick Up", for: .normal)
        pickUpButton.setTitleColor(.white, for: .normal)
        pickUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        pickUpButton.backgroundColor = Appearance.default.colorPalette.redPacketButton
        pickUpButton.clipsToBounds = true
        pickUpButton.layer.cornerRadius = 20
        pickUpButton.addTarget(self, action: #selector(btnPickButtonAction), for: .touchUpInside)
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
            timestampLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        timestampLabel.transform = .mirrorY
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
            descriptionLabel.textColor = Appearance.default.colorPalette.redPacketColor
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
        if let createdAt = content?.createdAt {
            timestampLabel?.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel?.text = nil
        }
    }

    @objc func btnPickButtonAction() {
        print("btnPickButtonAction")
    }

}
