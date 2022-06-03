//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

class AvatarView: UIImageView {
    override func updateConstraints() {
        super.updateConstraints()
        translatesAutoresizingMaskIntoConstraints = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        clipsToBounds = true
        layer.cornerRadius = frame.width / 2.0
        contentMode = .scaleAspectFill
    }
}
