//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Delegate responsible for easily assigning swipe action buttons to collectionView cells.
public protocol SwipeableViewDelegate: AnyObject {
    /// Prepares the receiver that showing of actionViews will ocur.
    /// use this method to for example close other actionViews in your collectionView/tableView.
    /// - Parameter indexPath: IndexPath of `collectionViewCell` which asks for action buttons.
    func swipeableViewWillShowActionViews(for indexPath: IndexPath)

    /// `ChatChannelListCollectionViewCell` can have swipe to delete / reveal action buttons on the cell.
    ///
    /// implementation of method should create those buttons and actions and be assigned easily to the cell
    /// in `UICollectionViewDataSource.cellForItemAtIndexPath` function.
    ///
    /// - Parameter indexPath: IndexPath of `collectionViewCell` which asks for action buttons.
    /// - Returns array of buttons revealed by swipe deletion.
    func swipeableViewActionViews(for indexPath: IndexPath) -> [UIView]
}

/// A view with swipe functionality that is used as action buttons view for channel list item view.
open class SwipeableView: _View, ComponentsProvider, UIGestureRecognizerDelegate {
    /// Gesture recognizer which is needed to be added on the owning view which will be recognizing the swipes.
    open private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(_:))
    )

    /// Returns whether the swipe action items are expanded or shrinked.
    open var isOpen: Bool { actionStackViewWidthConstraint?.constant != 0 }

    /// Minimum swiping velocity needed to fully expand or shrink action items when swiping.
    open var minimumSwipingVelocity: CGFloat = 30

    /// Constraint the trailing anchor of your content to this anchor in order to move it with the swipe gesture.
    ///
    /// When the swipe view is closed, this anchor matches the trailing anchor of the swipe view. When the view
    /// is open, this anchor matches the leading anchor of the first button.
    public var contentTrailingAnchor: NSLayoutXAxisAnchor { actionItemsStackView.leadingAnchor }

    /// Constraint constant should be reset when view is being reused inside `UICollectionViewCell`.
    public var actionStackViewWidthConstraint: NSLayoutConstraint?

    /// `SwipeableViewDelegate` instance
    public weak var delegate: SwipeableViewDelegate?

    /// Value detecting start of the swipe gesture. We always start at 0
    private var startValue: CGFloat = 0

    /// The provider of cell index path. The IndexPath is used in here to pass some reference
    /// for the given cell in action buttons closure. We use this in delegate function
    /// calls `swipeableViewActionViews(forIndexPath)` and `swipeableViewWillShowActionViews(forIndexPath)`
    public var indexPath: (() -> IndexPath?)?

    /// The `UIStackView` that arranges buttons revealed by swipe gesture.
    open private(set) lazy var actionItemsStackView: UIStackView = UIStackView()
        .withoutAutoresizingMaskConstraints

    override open func setUp() {
        super.setUp()
        panGestureRecognizer.delegate = self
    }

    override open func setUpLayout() {
        super.setUpLayout()

        addSubview(actionItemsStackView)
        actionItemsStackView.pin(anchors: [.top, .trailing, .bottom, .height], to: self)

        actionStackViewWidthConstraint = actionItemsStackView.widthAnchor.pin(equalToConstant: startValue)
        actionStackViewWidthConstraint?.priority = .required
        actionStackViewWidthConstraint?.isActive = true

        actionItemsStackView.axis = .horizontal
        actionItemsStackView.alignment = .fill
        actionItemsStackView.distribution = .fillProportionally
    }

    // We continue with the swipe and assing how far we are to `swipedValue`.
    var swipedValue: CGFloat = 0

    @objc open func handlePan(_ gesture: UIPanGestureRecognizer) {
        // If we don't have indexPath or any actionViews, we don't want to proceed with the swiping.
        guard let indexPath = indexPath?(),
              let actionButtons = delegate?.swipeableViewActionViews(for: indexPath),
              actionButtons.isEmpty == false
        else { return }

        var swipeVelocity = gesture.velocity(in: self)
        var swipePosition = gesture.translation(in: self)

        // If the language is Left to right, we need to switch the swipe direction, so we just negate it.
        // If the language is Right to left, we keep the swipe direction as is.
        if !currentLanguageIsRightToLeftDirection {
            swipePosition.x.negate()
            swipeVelocity.x.negate()
        }

        switch gesture.state {
        case .began:
            // If actionButtonStackView is not open, create the action buttons to show.
            if !isOpen {
                // Prepare the delegate that actionViews will be shown on some cell to
                // reset other cells states or do some other cleanup.
                delegate?.swipeableViewWillShowActionViews(for: indexPath)

                // Remove all subviews and add them to prevent having duplicities for views.
                actionItemsStackView.removeAllArrangedSubviews()
                actionButtons.forEach { actionItemsStackView.addArrangedSubview($0) }
            }
            startValue = actionStackViewWidthConstraint?.constant ?? 0
        case .cancelled, .failed:
            actionStackViewWidthConstraint?.constant = 0
        case .changed:
            if swipePosition.x < 0 {
                swipedValue = startValue + swipePosition.x
            } else {
                swipedValue = max(0, startValue + swipePosition.x)
            }
            actionStackViewWidthConstraint?.constant = swipedValue
        case .ended:
            // If everything went well and we swiped more than the width of the `actionStackView`,
            // we reveal the action items animated, else we just close
            let idealWidth = actionItemsStackView.idealWidth

            if swipeVelocity.x < -minimumSwipingVelocity {
                actionStackViewWidthConstraint?.constant = 0
            } else if swipedValue > idealWidth / 2.0 || swipeVelocity.x > minimumSwipingVelocity {
                actionStackViewWidthConstraint?.constant = idealWidth
            } else {
                actionStackViewWidthConstraint?.constant = 0
            }

            Animate { self.superview?.layoutIfNeeded() }
        default:
            break
        }
    }

    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let recognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

        // Fetch the swipe movement in the cell view. If horizontal swipe is detected,
        // we allow the gestureRecognizer to continue the swipe, if it's vertical,
        // we deny it so we can continue on showing the cell option menu only in horizontal way.
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

    /// Closes the stackView with buttons.
    public func close() {
        actionStackViewWidthConstraint?.constant = 0
    }
}

private extension UIStackView {
    /// The ideal width of the stack view calculated by calling `systemLayoutSizeFitting` on all arranged subviews.
    var idealWidth: CGFloat {
        arrangedSubviews.reduce(0) {
            let targetSize = CGSize(
                width: 0,
                height: $1.bounds.height
            )

            return $0 + $1.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .defaultLow,
                verticalFittingPriority: .required
            ).width
        }
    }
}
