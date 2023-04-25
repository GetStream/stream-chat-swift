//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class RecordButton: _Button, AppearanceProvider, ComponentsProvider {
    private var timer: Foundation.Timer?

    open var completedHandler: (() -> Void)?
    open var incompleteHandler: (() -> Void)?

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        addTarget(self, action: #selector(didTouchDown), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        setImage(appearance.images.mic.tinted(with: appearance.colorPalette.textLowEmphasis), for: .normal)
        setImage(appearance.images.mic.tinted(with: appearance.colorPalette.accentPrimary), for: .highlighted)
    }

    // MARK: - Action Handlers

    @objc open func didTouchDown(_ sender: UIButton) {
        timer?.invalidate()
        sender.isHighlighted = true
        timer = .scheduledTimer(
            withTimeInterval: components.asyncMessagesMinimumPressDuration,
            repeats: false,
            block: { [weak self] _ in
                sender.isHighlighted = false
                self?.timer = nil
                self?.completedHandler?()
            }
        )
    }

    @objc open func didTouchUp(_ sender: UIButton) {
        sender.isHighlighted = false
        if timer != nil {
            incompleteHandler?()
        }
        timer?.invalidate()
        timer = nil
    }
}
