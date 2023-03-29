//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class RecordButton: _Button, AppearanceProvider {
    open var minimumLongPressDuration: Double = 0.7

    open var possibleLongPressHandler: (() -> Void)?
    open var completedLongPressHandler: (() -> Void)?
    open var activeLongPressHandler: (() -> Void)?
    open var nonCompletedLongPressHandler: (() -> Void)?

    override open func setUp() {
        super.setUp()
        let gestureRecognizer = LongPressDurationGestureRecognizer(
            minimumInterval: minimumLongPressDuration
        )

        gestureRecognizer.possibleHandler = { [weak self] in
            self?.possibleLongPressHandler?()
        }
        gestureRecognizer.activeHandler = { [weak self] in
            self?.activeLongPressHandler?()
        }
        gestureRecognizer.completedHandler = { [weak self] in
            self?.completedLongPressHandler?()
        }
        gestureRecognizer.nonCompletedHandler = { [weak self] in
            self?.nonCompletedLongPressHandler?()
        }

        addGestureRecognizer(gestureRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        let normalStateImage = appearance.images.mic
        setImage(normalStateImage, for: .normal)

        let buttonColor: UIColor = appearance.colorPalette.alternativeInactiveTint
        let disabledStateImage = appearance.images.mic.tinted(with: buttonColor)
        setImage(disabledStateImage, for: .disabled)
    }
}

extension RecordButton {
    private final class LongPressDurationGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
        private let minimumInterval: Double
        var possibleHandler: (() -> Void)?
        var completedHandler: (() -> Void)?
        var activeHandler: (() -> Void)?
        var nonCompletedHandler: (() -> Void)?

        private var timer: Timer?
        private var startTime: Date?
        private var duration: Double = 0.0

        init(
            minimumInterval: Double
        ) {
            self.minimumInterval = minimumInterval
            super.init(target: nil, action: nil)
            delegate = delegate
        }

        override func touchesBegan(
            _ touches: Set<UITouch>,
            with event: UIEvent
        ) {
            startTime = Date() // now
            duration = 0
            state = .possible
            possibleHandler?()
            timer = Timer.scheduledTimer(
                withTimeInterval: minimumInterval,
                repeats: false,
                block: { [weak self] _ in self?.activeHandler?() }
            )
        }

        override func touchesEnded(
            _ touches: Set<UITouch>,
            with event: UIEvent
        ) {
            super.touchesEnded(touches, with: event)

            timer?.invalidate()
            timer = nil

            if let startTime = startTime,
               Date().timeIntervalSince(startTime) < minimumInterval {
                nonCompletedHandler?()
            } else {
                completedHandler?()
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
