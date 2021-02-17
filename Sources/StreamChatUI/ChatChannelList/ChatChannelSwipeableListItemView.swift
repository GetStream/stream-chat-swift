//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view with swipe functionality that is used as base view for channel list item view.
public typealias ChatChannelSwipeableListItemView = _ChatChannelSwipeableListItemView<NoExtraData>

/// A view with swipe functionality that is used as base view for channel list item view.
open class _ChatChannelSwipeableListItemView<ExtraData: ExtraDataTypes>: View, UIConfigProvider, UIGestureRecognizerDelegate {
    /// Constraint constant should be reset when view is being reused inside `UICollectionViewCell`.
    public var trailingConstraint: NSLayoutConstraint?
    
    /// The closure that will be triggered on delete button tap.
    public var deleteButtonAction: (() -> Void)?

    /// The main content view which you should always use for embedding your cell content.
    open private(set) lazy var cellContentView: UIView = UIView().withoutAutoresizingMaskConstraints
    
    /// The delete button.
    open private(set) lazy var deleteButton: UIButton = UIButton().withoutAutoresizingMaskConstraints
    
    /// The `UIStackView` that arranges buttons revealed by swipe gesture.
    open private(set) lazy var actionButtonStack: UIStackView = UIStackView().withoutAutoresizingMaskConstraints
    
    /// The view used as separator when this view is embedded in `UICollectionViewCell`.
    open private(set) lazy var bottomSeparatorView: UIView = UIView().withoutAutoresizingMaskConstraints
    
    override open func setUp() {
        super.setUp()

        deleteButton.addTarget(self, action: #selector(didTapDelete), for: .touchUpInside)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
    }

    override open func setUpLayout() {
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
        
        addSubview(bottomSeparatorView)
        bottomSeparatorView.heightAnchor.pin(equalToConstant: 0.4).isActive = true
        bottomSeparatorView.pin(anchors: [.bottom, .leading, .trailing], to: self)
    }

    override public func defaultAppearance() {
        super.defaultAppearance()

        bottomSeparatorView.backgroundColor = uiConfig.colorPalette.border

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

    public func gestureRecognizer(
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
    
    public func gestureRecognizer(
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
