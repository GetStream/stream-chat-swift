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
    public lazy var dateFormatter: DateFormatter = .makeDefault()

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
        addSubview(viewContainer)
        NSLayoutConstraint.activate([
            viewContainer.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
            viewContainer.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4)
        ])
        if isSender {
            viewContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: cellWidth).isActive = true
            viewContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8).isActive = true
        } else {
            viewContainer.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8).isActive = true
            viewContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -cellWidth).isActive = true
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
        descriptionLabel.text = "Sweet! \nYou just picked up 15 ONE! \n\n🧧Red Packet"

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
    }
}
