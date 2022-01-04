//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class iMessageCellSeparatorView: CellSeparatorReusableView {
    override func setUpLayout() {
        super.setUpLayout()
        NSLayoutConstraint.activate([
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 73)
        ])
    }
}
