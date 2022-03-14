//
//  PrivateGroupUsersCVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import Nuke

class PrivateGroupUsersCVCell: UICollectionViewCell {

    static let identifier = "PrivateGroupUsersCVCell"
    // MARK: - Outlets
    @IBOutlet private weak var imgAvatar: UIImageView!
    @IBOutlet private weak var lblUserName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    // MARK: - Functions
    func configData(data: ChatChannelMember) {
        NukeImageLoader().loadImage(into: imgAvatar, url: data.imageURL, imageCDN: StreamImageCDN(), placeholder: Appearance.default.images.userAvatarPlaceholder4, resize: true) { result in
            print(result)
        }
        lblUserName.text = data.name
        imgAvatar.cornerRadius = 35
        imgAvatar.layoutIfNeeded()
    }

}
