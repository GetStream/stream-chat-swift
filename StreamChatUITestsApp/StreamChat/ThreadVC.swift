//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatUI
import UIKit

final class ThreadVC: ChatThreadVC {
    var onViewWillAppear: ((ChatThreadVC) -> Void)?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewWillAppear?(self)
    }
}
