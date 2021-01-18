//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

// TODO:
public enum ChatChannelDetailAction {
    // TODO:
    case toggle(
        leadingIcon: UIImage?,
        title: String,
        action: (ChatChannelDetailVC) -> Void
    )
    // TODO:
    case selection(
        leadingIcon: UIImage?,
        title: String,
        trailingIcon: UIImage?,
        action: (ChatChannelDetailVC) -> Void
    )
    // TODO:
    case destructive(
        title: String,
        trailingIcon: UIImage?,
        action: (ChatChannelDetailVC) -> Void
    )
    // TODO:
    case info(
        title: String,
        value: (ChatChannelDetailVC) -> String
    )
}
