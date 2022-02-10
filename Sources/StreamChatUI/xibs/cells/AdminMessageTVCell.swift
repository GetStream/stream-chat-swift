//
//  ChatMessageTVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 08/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class AdminMessageTVCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var lblTime: UILabel!

    // MARK: - Variables
    var content: ChatMessage?
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    
    // MARK: - View life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Functions
    func configCell() {
        if let createdAt = content?.createdAt {
            lblTime.text = dateFormatter.string(from: createdAt)
        } else {
            lblTime.text = nil
        }
        lblDesc.text = content?.extraData.adminMessage
    }
}
