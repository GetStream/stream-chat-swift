//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class AttachmentsPreviewVC: _ViewController, ComponentsProvider {
    /// The attachment previews content.
    open var content: [AttachmentPreviewProvider] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The maximum number of vertical items before scrolling is enabled.
    open var maxNumberOfVerticalItems: Int = 3

    /// The closure handler when an attachment has been removed.
    open var didTapRemoveItemButton: ((Int) -> Void)?

    /// The scroll view that contains the horizontal and vertical stacks.
    open private(set) lazy var scrollView: UIScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints

    /// The container stack that holds the vertical and horizontal items.
    open private(set) lazy var containerStackView = ContainerStackView(
        axis: .vertical,
        spacing: 8
    ).withoutAutoresizingMaskConstraints

    /// The stack used to display the attachments previews horizontally.
    open private(set) lazy var horizontalStackView = ContainerStackView(
        axis: .horizontal,
        spacing: 8
    ).withoutAutoresizingMaskConstraints

    /// The stack used to display the attachments previews vertically.
    open private(set) lazy var verticalStackView = ContainerStackView(
        axis: .vertical,
        spacing: 8
    ).withoutAutoresizingMaskConstraints

    /// The current scroll view height used to activate the scrolling on the vertical stack.
    public var scrollViewHeightConstraint: NSLayoutConstraint?
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        horizontalStackView.backgroundColor = .clear
        horizontalStackView.isLayoutMarginsRelativeArrangement = true

        verticalStackView.backgroundColor = .clear
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        view.embed(scrollView)
        scrollView.embed(containerStackView)
        containerStackView.addArrangedSubview(horizontalStackView)
        containerStackView.addArrangedSubview(verticalStackView)
        horizontalStackView.isHidden = true
        verticalStackView.isHidden = true

        scrollView.heightAnchor.pin(equalTo: containerStackView.heightAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: verticalStackView.widthAnchor).isActive = true
    }
    
    open var attachmentViews: [UIView] {
        content.enumerated().map { index, attachment in
            let view = attachment.previewView(components: components)
                .withoutAutoresizingMaskConstraints
            let cell = components.messageComposerAttachmentCell.init()
                .withoutAutoresizingMaskConstraints
            cell.embed(attachmentView: view)
            cell.discardButtonHandler = { [weak self] in self?.didTapRemoveItemButton?(index) }
            return cell
        }
    }
    
    open var stackViewAxis: NSLayoutConstraint.Axis {
        content.first.flatMap { type(of: $0).preferredAxis } ?? .horizontal
    }
    
    override open func updateContent() {
        super.updateContent()
        
        switch stackViewAxis {
        case .horizontal:
            setupHorizontalStackView()
            
        case .vertical:
            setupVerticalStackView()
            
        @unknown default:
            break
        }
    }
    
    open func setupHorizontalStackView() {
        // Re-enable scroll
        scrollView.isScrollEnabled = true

        horizontalStackView.isHidden = false
        verticalStackView.isHidden = true
        
        horizontalStackView.removeAllArrangedSubviews()
        horizontalStackView.addArrangedSubviews(attachmentViews)
    }
    
    open func setupVerticalStackView() {
        // Disable scroll when not needed
        scrollView.isScrollEnabled = content.count > maxNumberOfVerticalItems
        
        let attachmentViews = attachmentViews

        // If the content is bigger than the max vertical items and the scroll view height
        // constraint is not yet created, append to the vertical constraint and activate it.
        if content.count > maxNumberOfVerticalItems, let firstAttachmentView = attachmentViews.first {
            if scrollViewHeightConstraint == nil {
                let attachmentHeight = firstAttachmentView
                    .systemLayoutSizeFitting(.init(width: CGFloat.infinity, height: CGFloat.infinity))
                    .height
                let spacingSize = CGFloat(attachmentViews.count + 1) * verticalStackView.spacing.rawValue
                let maxScrollViewHeight: CGFloat = CGFloat(maxNumberOfVerticalItems) * attachmentHeight + spacingSize
                
                scrollViewHeightConstraint = scrollView.heightAnchor.pin(
                    lessThanOrEqualToConstant: maxScrollViewHeight
                )
                scrollViewHeightConstraint?.isActive = true
            }
            // If the content is lower than the max vertical items,
            // reset the scroll view height constraint.
        } else {
            scrollViewHeightConstraint?.isActive = false
            scrollViewHeightConstraint = nil
        }

        horizontalStackView.isHidden = true
        verticalStackView.isHidden = false
        
        verticalStackView.removeAllArrangedSubviews()
        verticalStackView.addArrangedSubviews(attachmentViews)
    }
}
