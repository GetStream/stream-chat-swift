//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class PlayPauseButton: _Button, AppearanceProvider {
    open var content: Bool = false {
        didSet { updateContent() }
    }

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
            setImage(UIImage(systemName: "play"), for: .normal)
            setImage(UIImage(systemName: "pause"), for: .selected)
        }

        tintColor = appearance.colorPalette.accentPrimary
    }

    @objc private func didTap(_ sender: PlayPauseButton) {
        didTapHandler?()
        content.toggle()
    }

    override open func updateContent() {
        super.updateContent()
        isSelected = content
    }
}
