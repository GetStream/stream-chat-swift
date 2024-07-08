//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// The view shown when the thread list is loading threads.
open class ChatThreadListLoadingView: _View, ThemeProvider {
    /// The loading indicator view.
    open private(set) lazy var loadingIndicator: UIActivityIndicatorView = {
        UIActivityIndicatorView(style: .large).withoutAutoresizingMaskConstraints
    }()

    override open func setUpLayout() {
        super.setUpLayout()

        embed(loadingIndicator)
        loadingIndicator.pin(anchors: [.centerX, .centerY], to: self)
        loadingIndicator.startAnimating()
    }
}
