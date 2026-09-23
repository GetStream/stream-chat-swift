//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
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

    override func awakeFromNib() {
        super.awakeFromNib()

        // The standard spacing and the default margins are not applied implicitly on every device,
        // which leaves the avatar touching the labels, so the row states them.
        mainStackView.directionalLayoutMargins = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        mainStackView.spacing = 12

        // The labels are laid out one after the other rather than sharing the row equally, which
        // gives them boxes taller than the space they have and makes them overlap.
        let labelsStackView = nameLabel.superview as? UIStackView
        labelsStackView?.isBaselineRelativeArrangement = false
        labelsStackView?.distribution = .fill
        labelsStackView?.spacing = 2
    }
}
