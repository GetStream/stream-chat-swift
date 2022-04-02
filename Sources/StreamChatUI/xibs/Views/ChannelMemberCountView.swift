//
//  ChannelMemberCountView.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 30/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class ChannelMemberCountView: UIView {

    // MARK: - Outlets
    @IBOutlet weak var lblparticipantsCount: UILabel!

    // MARK: - Life Cycle
    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    class func instanceFromNib() -> ChannelMemberCountView? {
        return UINib(nibName: "ChannelMemberCountView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? ChannelMemberCountView ?? nil
    }

    // MARK: - Functions
    func setParticipantsCount(_ count: Int) {
        if count <= 1 {
            lblparticipantsCount.text = "\(count) participant"
        } else {
            lblparticipantsCount.text = "\(count) participants"
        }
    }
}
