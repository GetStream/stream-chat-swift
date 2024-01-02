//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A button that is being used to enter the recording a new VoiceRecording flow.
open class RecordButton: _Button, AppearanceProvider, ComponentsProvider {
    /// The minimumPressDuration required to start the recording flow.
    public var minimumPressDuration: TimeInterval = 0.5

    /// The handler to be called once the touchDown event starts.
    open var touchDownHandler: (() -> Void)?

    /// The handler to be called once the scheduled event gets triggered.
    open var completedHandler: (() -> Void)?

    /// The handler to be called when the touchDown event completes before the scheduled event triggers.
    open var incompleteHandler: (() -> Void)?

    /// A property that shows if a an event has been schedule to be fired after the debouncing interval.
    private var hasScheduledEvent: Bool = false

    /// The object that will be used to schedule events and trigger them after an interval.
    private lazy var debouncer = Debouncer(
        minimumPressDuration,
        queue: .main
    )

    // MARK: - Lifecycle

    override open func setUp() {
        super.setUp()

        addTarget(self, action: #selector(didTouchDown), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpInside)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        setImage(
            appearance.images.mic.tinted(with: appearance.colorPalette.textLowEmphasis),
            for: .normal
        )
        setImage(
            appearance.images.mic.tinted(with: appearance.colorPalette.accentPrimary),
            for: .highlighted
        )
    }

    // MARK: - Action Handlers

    @objc open func didTouchDown(_ sender: UIButton) {
        // Inform the touchDown handler about the newly starting touchDown event.
        touchDownHandler?()

        // Invalidate any scheduled events.
        debouncer.invalidate()

        // Update the button's UI state.
        sender.isHighlighted = true

        // Schedule a new event to be fired after the debouncing interval.
        debouncer.execute { [weak self] in
            self?.hasScheduledEvent = false
            sender.isHighlighted = false
            self?.completedHandler?()
        }

        // Keep a reference to know that we have an event scheduled.
        hasScheduledEvent = true
    }

    @objc open func didTouchUp(_ sender: UIButton) {
        // If we have an event scheduled, we want to inform that the event won't
        // be completed.
        if hasScheduledEvent { incompleteHandler?() }

        // Update the button's UI state.
        sender.isHighlighted = false

        // Invalidate any scheduled events.
        debouncer.invalidate()
    }
}
