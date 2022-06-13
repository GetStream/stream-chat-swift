//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class UserCredentialsCell: UITableViewCell {
    @IBOutlet var mainStackView: UIStackView! {
        didSet {
            mainStackView.isLayoutMarginsRelativeArrangement = true
        }
    }

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var accessoryImageView: UIImageView!

    var user: ChatUser?
}
