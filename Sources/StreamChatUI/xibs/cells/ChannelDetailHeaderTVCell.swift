//
//  ChannelDetailHeaderTVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 15/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import DocsSnippets

class ChannelDetailHeaderTVCell: UITableViewCell {

    // MARK: - variables
    
    // MARK: - outlets
    @IBOutlet weak var imgProfile: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    
    // MARK: - view life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    // MARK: - functions
    private func setupUI() {
        imgProfile.layer.cornerRadius = imgProfile.frame.size.height / 2
        imgProfile.backgroundColor = .red
        lblTitle
    }
    
}
