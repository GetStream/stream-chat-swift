//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class BiDirectionalPanGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {
    open var shouldReceiveEventHandler: (() -> Bool)?
    open var horizontalMovementHandler: ((CGFloat) -> Void)?
    open var verticalMovementHandler: ((CGFloat) -> Void)?
    open var completionHandler: (() -> Void)?
    open var touchesBeganHandler: (() -> Void)?

    private var initialVerticalPoint: CGFloat?
    private var horizontalPoint: CGFloat = 0
    private var verticalPoint: CGFloat = 0

    override open func reset() {
        super.reset()
        horizontalPoint = view?.bounds.width ?? 0
        verticalPoint = initialVerticalPoint ?? view?.bounds.height ?? 0

        // Fix for the increased height of ComposerView due to the attachments
        // preview
        if initialVerticalPoint == nil {
            initialVerticalPoint = verticalPoint
        }
    }

    init() {
        super.init(target: nil, action: nil)
        delegate = self
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    override open func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        let result = shouldReceiveEventHandler?() ?? false
        guard result else {
            state = .possible
            return
        }

        reset()
        super.touchesBegan(touches, with: event)
        touchesBeganHandler?()
    }

    override open func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        super.touchesMoved(touches, with: event)
        let velocity = self.velocity(in: view)
        let translation = super.translation(in: view)
        let isHorizontalMovement = abs(velocity.x) >= abs(velocity.y)

        if isHorizontalMovement {
            horizontalPoint += translation.x
            horizontalMovementHandler?(horizontalPoint)
        } else {
            verticalPoint += translation.y
            verticalMovementHandler?(verticalPoint)
        }

        setTranslation(.zero, in: view)
    }

    override open func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        super.touchesEnded(touches, with: event)
        completionHandler?()
        reset()
    }
}
