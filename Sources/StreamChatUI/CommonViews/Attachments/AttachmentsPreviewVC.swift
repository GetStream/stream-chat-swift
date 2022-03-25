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

    /// The container stack that holds the vertical and horizontal items.
    open private(set) lazy var containerStackView = ContainerStackView(
        axis: .vertical,
        spacing: 8
    ).withoutAutoresizingMaskConstraints
    
    /// The scroll view that contains the horizontal stack.
    open private(set) lazy var horizontalScrollView: UIScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints

    /// The stack used to display the attachments previews horizontally.
    open private(set) lazy var horizontalStackView = ContainerStackView(
        axis: .horizontal,
        spacing: 8
    ).withoutAutoresizingMaskConstraints
    
    /// The scroll view that contains the vertical stack.
    open private(set) lazy var verticalScrollView: UIScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints

    /// The stack used to display the attachments previews vertically.
    open private(set) lazy var verticalStackView = ContainerStackView(
        axis: .vertical,
        spacing: 8
    ).withoutAutoresizingMaskConstraints

    /// The current scroll view height used to activate the scrolling on the vertical stack.
    public var verticalScrollViewHeightConstraint: NSLayoutConstraint?

    /// The attachment views for each attachment preview.
    ///
    /// - Parameter axises: The desired axises of which the previews belong.
    ///   An attachment preview can be rendered vertically or horizontally.
    /// - Returns: The attachment previews.
    open func attachmentPreviews(for axises: Set<NSLayoutConstraint.Axis>) -> [UIView] {
        content
            .enumerated()
            .filter { _, attachment in axises.contains(type(of: attachment).preferredAxis) }
            .map { index, attachment in
                let view = attachment.previewView(components: components)
                    .withoutAutoresizingMaskConstraints
                let cell = components.messageComposerAttachmentCell.init()
                    .withoutAutoresizingMaskConstraints
                cell.embed(attachmentView: view)
                cell.discardButtonHandler = { [weak self] in self?.didTapRemoveItemButton?(index) }
                return cell
            }
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        horizontalStackView.backgroundColor = .clear
        horizontalStackView.isLayoutMarginsRelativeArrangement = true

        verticalStackView.backgroundColor = .clear
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        
        horizontalScrollView.backgroundColor = .clear
        horizontalScrollView.showsHorizontalScrollIndicator = false
        horizontalScrollView.showsVerticalScrollIndicator = false
        
        verticalScrollView.backgroundColor = .clear
        verticalScrollView.showsHorizontalScrollIndicator = false
        verticalScrollView.showsVerticalScrollIndicator = false
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        view.embed(containerStackView)
        
        horizontalScrollView.embed(horizontalStackView)
        containerStackView.addArrangedSubview(horizontalScrollView)
        
        verticalScrollView.embed(verticalStackView)
        containerStackView.addArrangedSubview(verticalScrollView)
        
        horizontalScrollView.isHidden = true
        verticalScrollView.isHidden = true
        
        horizontalScrollView.heightAnchor.pin(equalTo: horizontalStackView.heightAnchor).isActive = true
        horizontalScrollView.widthAnchor.pin(equalTo: verticalStackView.widthAnchor).isActive = true
        
        verticalScrollView.heightAnchor.pin(equalTo: verticalStackView.heightAnchor).isActive = true
        verticalScrollView.widthAnchor.pin(equalTo: verticalStackView.widthAnchor).isActive = true
    }
    
    override open func updateContent() {
        super.updateContent()
        
        horizontalScrollView.isHidden = true
        verticalScrollView.isHidden = true
        
        let axises = Set(content.map { type(of: $0).preferredAxis })
        
        if axises.contains(.horizontal) {
            setupHorizontalStackView()
        }
        
        if axises.contains(.vertical) {
            setupVerticalStackView()
        }
    }
    
    open func setupHorizontalStackView() {
        horizontalScrollView.isHidden = false

        let horizontalAttachmentPreviews = attachmentPreviews(for: [.horizontal])
        horizontalStackView.removeAllArrangedSubviews()
        horizontalStackView.addArrangedSubviews(horizontalAttachmentPreviews)
        // Spacer
        horizontalStackView.addArrangedSubview(UIView())
    }
    
    open func setupVerticalStackView() {
        verticalScrollView.isHidden = false

        let verticalAttachmentPreviews = attachmentPreviews(for: [.vertical])
        verticalStackView.removeAllArrangedSubviews()
        verticalStackView.addArrangedSubviews(verticalAttachmentPreviews)

        // If the content is bigger than the max vertical items and the scroll view height
        // constraint is not yet created, append to the vertical constraint and activate it.
        if verticalAttachmentPreviews.count > maxNumberOfVerticalItems, let firstAttachmentView = verticalAttachmentPreviews.first {
            if verticalScrollViewHeightConstraint == nil {
                let attachmentHeight = firstAttachmentView
                    .systemLayoutSizeFitting(.init(width: CGFloat.infinity, height: CGFloat.infinity))
                    .height
                let spacingSize = CGFloat(verticalAttachmentPreviews.count + 1) * verticalStackView.spacing.rawValue
                let maxScrollViewHeight: CGFloat = CGFloat(maxNumberOfVerticalItems) * attachmentHeight + spacingSize

                verticalScrollViewHeightConstraint = verticalScrollView.heightAnchor.pin(
                    lessThanOrEqualToConstant: maxScrollViewHeight
                )
                verticalScrollViewHeightConstraint?.isActive = true
            }

            // When adding a vertical attachment, make sure the last item is visible
            scrollVerticalViewToBottom()
        } else {
            // If the content is lower than the max vertical items,
            // reset the scroll view height constraint.
            verticalScrollViewHeightConstraint?.isActive = false
            verticalScrollViewHeightConstraint = nil
        }
    }

    // Scrolls to the bottom of the vertical scroll view.
    open func scrollVerticalViewToBottom() {
        if let lastAttachmentView = verticalScrollView.subviews.last {
            DispatchQueue.main.async {
                self.verticalScrollView.scrollRectToVisible(lastAttachmentView.frame, animated: true)
            }
        }
    }
}
