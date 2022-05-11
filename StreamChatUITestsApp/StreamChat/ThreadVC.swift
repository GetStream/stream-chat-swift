//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit
import StreamChatUI

final class ThreadVC: ChatThreadVC {

    var onViewWillAppear: ((ChatThreadVC) -> Void)?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onViewWillAppear?(self)
    }
    
}
