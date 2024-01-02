//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A PanGestureRecogniser that can detect when a touch is moving horizontally or vertically.
open class BidirectionalPanGestureRecogniser: UIPanGestureRecognizer {
    // MARK: - Handlers

    /// A closure that will be called every time the recogniser gets an horizontal movement
    open var horizontalMovementHandler: ((CGFloat) -> Void)?

    /// A closure that will be called every time the recogniser gets a vertical movement
    open var verticalMovementHandler: ((CGFloat) -> Void)?

    /// A closure that will be called when touches began
    open var touchesBeganHandler: (() -> Void)?

    /// A closure that will be called when touches end
    open var touchesEndedHandler: (() -> Void)?

    // MARK: - Private Properties

    /// The point which the we consider as the bottom position to begin from
    private var initialVerticalPoint: CGFloat?

    /// The current horizontal movement translated to view's width
    private var horizontalPoint: CGFloat = 0

    /// The current vertical movement translated to view's height
    private var verticalPoint: CGFloat = 0

    // MARK: - Lifecycle

    /// Reset the gesture recognizer's state
    override open func reset() {
        super.reset()

        // As we are expecting the receiving view to be at the view's trailing side,
        // we set the current horizontal position to the view's width, or 0 if the
        // view is nil.
        horizontalPoint = view?.bounds.width ?? 0

        // As we are expecting the receiving view to be at the view's bottom side,
        // we set the current vertical position to initialVerticalPoint(to
        // accommodate for the attachment preview in the composer) or the view's
        // height, or 0 if the view is nil.
        verticalPoint = initialVerticalPoint ?? view?.bounds.height ?? 0

        // Fix for the increased height of ComposerView due to the attachments preview
        if initialVerticalPoint == nil { initialVerticalPoint = verticalPoint }
    }

    override open func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        // Reset the gesture recognizer's state as we would like to start from
        // a clean state.
        reset()

        super.touchesBegan(touches, with: event)

        touchesBeganHandler?()
    }

    override open func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        super.touchesMoved(touches, with: event)

        // Get the velocity of the gesture
        let velocity = self.velocity(in: view)

        // Get the translation of the gesture
        let translation = super.translation(in: view)

        // Check if the gesture is moving horizontally
        let isHorizontalMovement = abs(velocity.x) >= abs(velocity.y)

        // If the gesture is moving horizontally
        if isHorizontalMovement {
            // Update the current horizontal position
            horizontalPoint += translation.x

            // Call the horizontal movement handler closure
            horizontalMovementHandler?(horizontalPoint)
        } else { // If the gesture is moving vertically
            // Update the current vertical position
            verticalPoint += translation.y

            // Call the vertical movement handler closure
            verticalMovementHandler?(verticalPoint)
        }

        // Reset the translation of the gesture
        setTranslation(.zero, in: view)
    }

    override open func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        super.touchesEnded(touches, with: event)
        touchesEndedHandler?()
        reset()
    }
}
