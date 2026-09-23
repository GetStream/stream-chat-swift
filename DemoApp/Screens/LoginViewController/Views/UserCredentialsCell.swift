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
        // which leaves the avatar touching the labels, so the row states them. The vertical ones
        // stay with the cell, which is laid out in a fixed height the row has to fit in.
        mainStackView.directionalLayoutMargins = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        mainStackView.spacing = 12

        // The labels are laid out one after the other rather than sharing the row equally, which
        // gives them boxes taller than the space they have and makes them overlap.
        let labelsStackView = nameLabel.superview as? UIStackView
        labelsStackView?.isBaselineRelativeArrangement = false
        labelsStackView?.distribution = .fill
        labelsStackView?.spacing = 2

        // The avatar is round, which needs it square. One of the rows this cell is used in asks for
        // a width of its own without a ratio, and the height the row leaves then draws it as an
        // oval, so the ratio wins and the width gives way.
        avatarView.constraints
            .filter { $0.firstAttribute == .width && $0.secondItem == nil }
            .forEach { $0.priority = .init(999) }
        avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor).isActive = true
    }
}
