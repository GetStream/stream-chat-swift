//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

extension ChatChannelUserDetailVC {
    // TODO:
    public enum Action {
        // TODO:
        case toggle(
            leadingIcon: UIImage?,
            title: String,
            action: (ChatChannelUserDetailVC, _ isOn: Bool) -> Void
        )
        // TODO:
        case selection(
            leadingIcon: UIImage?,
            title: String,
            trailingIcon: UIImage?,
            action: (ChatChannelUserDetailVC) -> Void
        )
        // TODO:
        case destructive(
            leadingIcon: UIImage?,
            title: String,
            action: (ChatChannelUserDetailVC) -> Void
        )
        // TODO:
        case display(
            title: String,
            value: ((ChatChannelUserDetailVC) -> String),
            action: ((ChatChannelUserDetailVC) -> Void)?
        )
    }
}
