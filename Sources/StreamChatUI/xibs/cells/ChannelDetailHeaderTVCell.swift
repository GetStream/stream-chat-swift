//
//  ChannelDetailHeaderTVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 15/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class ChannelDetailHeaderTVCell: _TableViewCell, AppearanceProvider {

    // MARK: - variables
    
    // MARK: - outlets
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet var channelActionText: [UILabel]!
    @IBOutlet var containers: [UIView]!
    
    // MARK: - view life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - functions
    private func setupUI() {
        imgProfile.layer.cornerRadius = imgProfile.frame.size.height / 2
        imgProfile.backgroundColor = .red
        lblTitle.attributedText = getTitle()
        for label in channelActionText {
            label.textColor = appearance.colorPalette.subTitleColor
        }
        for container in containers {
            container.backgroundColor = appearance.colorPalette.groupDetailContainerBG
            container.layer.cornerRadius = 12
            container.clipsToBounds = true
        }
    }
    
    private func getTitle() -> NSMutableAttributedString? {
        guard let iconImage = appearance.images.starCircleFill?.tinted(with: appearance.colorPalette.statusColorBlue) else {
            return nil
        }
        let title = NSMutableAttributedString(string: "1wallet Tips ")
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = iconImage
        imageAttachment.bounds = .init(x: 0, y: -((lblTitle.font.capHeight - iconImage.size.height).rounded() / 2) - 3, width: iconImage.size.width, height: iconImage.size.height)
        let imageString = NSAttributedString(attachment: imageAttachment)
        title.append(imageString)
        return title
    }
}
