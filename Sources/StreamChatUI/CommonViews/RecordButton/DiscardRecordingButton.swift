//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class DiscardRecordingButton: _Button, AppearanceProvider {
    open var didTapHandler: (() -> Void)?

    override open func setUp() {
        super.setUp()
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        heightAnchor.constraint(equalToConstant: 40).isActive = true
        widthAnchor.constraint(equalToConstant: 28).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        if #available(iOS 13.0, *) {
            let normalStateImage = UIImage(systemName: "trash")
            setImage(normalStateImage, for: .normal)
        }

        tintColor = appearance.colorPalette.accentPrimary
    }

    @objc private func didTap(_ sender: StopRecordingButton) {
        didTapHandler?()
    }
}
