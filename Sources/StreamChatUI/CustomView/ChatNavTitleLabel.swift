//
//  ChatNavTitleLabel.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 16/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

public class ChatNavTitleLabel: UILabel {

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    public func setupUI() {
        self.setChatNavTitleColor()
    }

}
