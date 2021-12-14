//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A protocol for `ChatMessageListScrollOverlayView` data source.
public protocol ChatMessageListScrollOverlayDataSource: AnyObject {
    /// Get date for item at given index path
    /// - Parameters:
    ///   - overlay: A view requesting date
    ///   - indexPath: An index path that should be used to get the date
    func scrollOverlay(_ overlay: ChatMessageListScrollOverlayView, textForItemAt indexPath: IndexPath) -> String?
}

/// View that is displayed as top overlay when message list is scrolling
open class ChatMessageListScrollOverlayView: _View, ThemeProvider {
    /// The displayed content.
    open var content: String? {
        didSet { updateContentIfNeeded() }
    }

    /// A date separator view that shows the day of the current grouped messages.
    open lazy var dateSeparatorView: ChatMessageListDateSeparatorView = components
        .messageListDateSeparatorView.init()
        .withoutAutoresizingMaskConstraints
            
    /// The data source used to get the content to display.
    public weak var dataSource: ChatMessageListScrollOverlayDataSource?
    
    /// The list view that is listened for being scrolled.
    public weak var listView: UITableView? {
        didSet {
            contentOffsetObservation = listView?.observe(\.contentOffset) { [weak self] tb, _ in
                guard let self = self else { return }
                
                // To display correct date we use bottom edge of scroll overlay
                let refPoint = CGPoint(
                    x: self.center.x,
                    y: self.frame.maxY
                )
                
                // If we cannot find any indexPath for `cell` we try to use max visible indexPath (we have bottom to top) layout
                guard
                    let refPointInListView = self.superview?.convert(refPoint, to: tb),
                    let indexPath = tb.indexPathForRow(at: refPointInListView) ?? tb.indexPathsForVisibleRows?.max()
                else { return }
                
                let overlayText = self.dataSource?.scrollOverlay(self, textForItemAt: indexPath)
                
                // If we have no date we have no reason to display `dateView`
                self.isHidden = (overlayText ?? "").isEmpty
                self.content = overlayText
                
                // Apple's naming is quite weird as actually this property should rather be named `isScrolling`
                // as it stays true when user stops dragging and scrollView is decelerating and becomes false
                // when scrollView stops decelerating
                //
                // But this case doesn't cover situation when user drags scrollView to a certain `contentOffset`
                // leaves the finger there for a while and then just lifts it, it doesn't change `contentOffset`
                // so this handler is not called, this is handled by `scrollStateChanged`
                // that reacts on `panGestureRecognizer` states and can handle this case properly
                if !tb.isDragging {
                    self.setAlpha(0)
                }
            }
            
            oldValue?.panGestureRecognizer.removeTarget(self, action: #selector(scrollStateChanged))
            listView?.panGestureRecognizer.addTarget(self, action: #selector(scrollStateChanged))
        }
    }
    
    private var contentOffsetObservation: NSKeyValueObservation?
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        embed(dateSeparatorView)
    }
    
    override open func updateContent() {
        super.updateContent()

        dateSeparatorView.content = content
    }
    
    /// Is invoked when a pan gesture state is changed.
    @objc
    open func scrollStateChanged(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            setAlpha(1)
        case .ended, .cancelled, .failed:
            // This case handles situation when user pans to certain `contentOffset`, leaves the finger there
            // and then lifts it without `contentOffset` change, so `scrollView` will not decelerate, if it does,
            // it is handled by `contentOffset` observation
            if listView?.isDecelerating == false {
                setAlpha(0)
            }
        default: break
        }
    }
    
    /// Updates the alpha of the overlay.
    open func setAlpha(_ alpha: CGFloat) {
        Animate(isAnimated: true) {
            self.alpha = alpha
        }
    }
}
