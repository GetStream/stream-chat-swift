//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class StopRecordingButton: _Button, AppearanceProvider {
    open var didTapHandler: (() -> Void)?

    override open func setUp() {
        super.setUp()
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        if #available(iOS 13.0, *) {
            let normalStateImage = UIImage(systemName: "stop.circle")
            setImage(normalStateImage, for: .normal)
        }

        tintColor = appearance.colorPalette.alert
    }

    @objc private func didTap(_ sender: StopRecordingButton) {
        didTapHandler?()
    }
}
