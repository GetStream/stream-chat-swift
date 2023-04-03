//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class RecordButton: _Button, AppearanceProvider {
    private enum State {
        case none
        case tapped
        case longPressed
    }

    private var buttonState: State = .none {
        didSet {
            switch (oldValue, buttonState) {
            case (.tapped, .longPressed):
                isHighlighted = true
                activeLongPressHandler?()
            case (.tapped, .none):
                isHighlighted = false
                nonCompletedLongPressHandler?()
            case (.longPressed, .none):
                isHighlighted = false
                completedLongPressHandler?()
            case (.none, .tapped):
                isHighlighted = true
                possibleLongPressHandler?()
            default:
                isHighlighted = false
            }
        }
    }

    private lazy var longPressGestureRecognizer = UILongPressGestureRecognizer(
        target: self,
        action: #selector(longPressBegan)
    )

    open var possibleLongPressHandler: (() -> Void)?
    open var completedLongPressHandler: (() -> Void)?
    open var activeLongPressHandler: (() -> Void)?
    open var nonCompletedLongPressHandler: (() -> Void)?

    @objc private func longPressBegan(
        _ gestureRecognizer: UILongPressGestureRecognizer
    ) {
        guard buttonState == .tapped else {
            return
        }

        buttonState = .longPressed
        activeLongPressHandler?()
        gestureRecognizer.isEnabled = false
        gestureRecognizer.isEnabled = true
        buttonState = .none
    }

    @objc private func didTouchDown(_ sender: UIButton) {
        buttonState = .tapped
    }

    @objc private func didTouchUp(_ sender: UIButton) {
        buttonState = .none
    }

    override open func setUp() {
        super.setUp()

        longPressGestureRecognizer.minimumPressDuration = 1
        addGestureRecognizer(longPressGestureRecognizer)

        addTarget(self, action: #selector(didTouchDown), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        setImage(appearance.images.mic, for: .normal)
    }
}
