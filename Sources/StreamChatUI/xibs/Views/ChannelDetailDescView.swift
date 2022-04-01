//
//  ChannelDetailDescView.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 30/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

class ChannelDetailDescView: UIView {

    // MARK: - Outlets
    @IBOutlet weak var viewQRCode: UIView!
    @IBOutlet weak var btnQRCode: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var viewSeparator: UIView!

    // MARK: - Life Cycle
    override class func awakeFromNib() {
        super.awakeFromNib()
    }

    class func instanceFromNib() -> ChannelDetailDescView? {
        return UINib(nibName: "ChannelDetailDescView", bundle: nil)
            .instantiate(withOwner: nil, options: nil)[0] as? ChannelDetailDescView ?? nil
    }

}
