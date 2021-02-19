//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view with swipe functionality that is used as base view for channel list item view.
internal typealias ChatChannelSwipeableListItemView = _ChatChannelSwipeableListItemView<NoExtraData>

/// A view with swipe functionality that is used as base view for channel list item view.
internal class _ChatChannelSwipeableListItemView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider, UIGestureRecognizerDelegate {
    /// Constraint constant should be reset when view is being reused inside `UICollectionViewCell`.
    internal var trailingConstraint: NSLayoutConstraint?
    
    /// The closure that will be triggered on delete button tap.
    internal var deleteButtonAction: (() -> Void)?

    /// The main content view which you should always use for embedding your cell content.
    internal private(set) lazy var cellContentView: UIView = uiConfig
        .channelList
        .swipeableItemSubviews
        .cellContentView
        .init().withoutAutoresizingMaskConstraints
    
    /// The delete button.
    internal private(set) lazy var deleteButton: UIButton = uiConfig
        .channelList
        .swipeableItemSubviews
        .deleteButton
        .init().withoutAutoresizingMaskConstraints
    
    /// The `UIStackView` that arranges buttons revealed by swipe gesture.
    internal private(set) lazy var actionButtonStack: UIStackView = uiConfig
        .channelList
        .swipeableItemSubviews
        .actionButtonStack
        .init().withoutAutoresizingMaskConstraints
    
    override internal func setUp() {
        super.setUp()

        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    override internal func setUpLayout() {
        super.setUpLayout()
        
        addSubview(cellContentView)
        cellContentView.pin(anchors: [.top, .bottom, .width], to: self)
        
        addSubview(actionButtonStack)
        actionButtonStack.addArrangedSubview(deleteButton)
        actionButtonStack.trailingAnchor.pin(greaterThanOrEqualTo: trailingAnchor).isActive = true
        actionButtonStack.pin(anchors: [.top, .bottom], to: self)
        actionButtonStack.axis = .horizontal
        actionButtonStack.alignment = .fill

        deleteButton.widthAnchor.pin(equalTo: deleteButton.heightAnchor).almostRequired.isActive = true
        deleteButton.heightAnchor.pin(equalTo: heightAnchor).isActive = true

        cellContentView.trailingAnchor.pin(equalTo: actionButtonStack.leadingAnchor).isActive = true
        trailingConstraint = trailingAnchor.pin(equalTo: cellContentView.trailingAnchor)
        trailingConstraint?.isActive = true
    }

    override internal func defaultAppearance() {
        super.defaultAppearance()

        deleteButton.setImage(uiConfig.images.messageActionDelete, for: .normal)

        deleteButton.backgroundColor = uiConfig.colorPalette.background1
        deleteButton.tintColor = uiConfig.colorPalette.alert
    }

    @objc open func didTapDelete() {
        deleteButtonAction?()
    }

    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        // Fetch the swipe movement in the cell view. If horizontal swipe is detected,
        // we allow the gestureRecognizer to continue the swipe, if it's horizontal,
        // we deny it so we can continue on showing the cell option menu.
        //
        // *This practically means on panning the cell we don't accidentally scroll the list
        let translation = recognizer.translation(in: self)

        return abs(translation.x) > abs(translation.y)
    }

    internal func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Default implementation of this function returns false, that means that gestureRecognizer
        // is not required to resign and we can have 2 simultaneous recognizers running at the same time.
        // by implementing this and set return to true, we deny any other touches to interfere.
        //
        // *This practically means on scrolling the list we don't accidentally reveal the cell actions.
        true
    }
    
    internal func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
    
    private var startedValue: CGFloat = 0
    private var maxActionWidth: CGFloat = 0

    @objc open func didPan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            startedValue = trailingConstraint?.constant ?? 0
            maxActionWidth = actionButtonStack.frame.width
        }

        let translation = gesture.translation(in: self)
        let value: CGFloat
        if translation.x < 0 {
            value = startedValue - translation.x
        } else {
            value = max(0, startedValue - translation.x)
        }

        if gesture.state == .cancelled || gesture.state == .failed {
            trailingConstraint?.constant = 0
            return
        }
        if gesture.state == .ended {
            if value > maxActionWidth / 2 {
                trailingConstraint?.constant = maxActionWidth
            } else {
                trailingConstraint?.constant = 0
            }

            Animate { self.layoutIfNeeded() }
            return
        }
        trailingConstraint?.constant = value
    }
}
