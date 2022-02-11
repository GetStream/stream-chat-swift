//
//  AvatarView.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 10/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

public class AvatarView: UIImageView {
    public override func updateConstraints() {
        super.updateConstraints()
        translatesAutoresizingMaskIntoConstraints = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = frame.width / 2.0
        contentMode = .scaleAspectFill
    }
}
