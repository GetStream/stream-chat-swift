//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view controller that displays a collection of attachments
public typealias AttachmentsPreviewVC = _AttachmentsPreviewVC<NoExtraData>

open class _AttachmentsPreviewVC: _ViewController, ComponentsProvider {
    open var content: [AttachmentPreviewProvider] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The closure handler when an attachment has been removed.
    open var didTapRemoveItemButton: ((Int) -> Void)?
    
    open var selectedAttachmentType: AttachmentType?
    
    public private(set) var scrollViewHeightConstraint: NSLayoutConstraint?
    open private(set) var horizontalConstraints: [NSLayoutConstraint] = []
    open private(set) var verticalConstraints: [NSLayoutConstraint] = []
    
    open private(set) lazy var scrollView: UIScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var horizontalStackView: ContainerStackView = ContainerStackView(axis: .horizontal, spacing: 8)
        .withoutAutoresizingMaskConstraints

    open private(set) lazy var verticalStackView: ContainerStackView = ContainerStackView(axis: .vertical, spacing: 8)
        .withoutAutoresizingMaskConstraints
    
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
        scrollView.embed(horizontalStackView)
        scrollView.embed(verticalStackView)
        
        horizontalConstraints.append(horizontalStackView.heightAnchor.pin(equalTo: scrollView.heightAnchor))
        verticalConstraints.append(verticalStackView.widthAnchor.pin(equalTo: scrollView.widthAnchor))
        
        scrollViewHeightConstraint = scrollView.heightAnchor.pin(equalToConstant: 0)
        scrollViewHeightConstraint?.isActive = true
    }
    
    open var attachmentViews: [UIView] {
        content.enumerated().map { index, attachment in
            let view = attachment.previewView(components: components).withoutAutoresizingMaskConstraints
            let cell = components.messageComposerAttachmentCell.init().withoutAutoresizingMaskConstraints
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
        let itemHeight: CGFloat = 100
        
        // Re-enable scroll
        scrollView.isScrollEnabled = true
        
        // Calculate height of the scroll view
        scrollViewHeightConstraint?.constant = itemHeight
            + horizontalStackView.layoutMargins.top
            + horizontalStackView.layoutMargins.bottom
        
        horizontalConstraints.forEach { $0.isActive = true }
        verticalConstraints.forEach { $0.isActive = false }
        
        horizontalStackView.isHidden = false
        verticalStackView.isHidden = true
        
        horizontalStackView.removeAllArrangedSubviews()
        horizontalStackView.addArrangedSubviews(attachmentViews)
    }
    
    open func setupVerticalStackView() {
        let maxNumberOfVisibleFiles = 3
        let itemHeight: CGFloat = 54
        
        // Disable scroll when not needed
        scrollView.isScrollEnabled = content.count > maxNumberOfVisibleFiles
        
        // Calculate height of the scroll view
        let numberOfVisibleItems = CGFloat(min(content.count, maxNumberOfVisibleFiles))
        let itemsHeight = itemHeight * numberOfVisibleItems
        let spacings = verticalStackView.spacing.rawValue * (numberOfVisibleItems - 1)
        let height = itemsHeight + spacings + verticalStackView.layoutMargins.top + verticalStackView.layoutMargins.bottom
        scrollViewHeightConstraint?.constant = height
        
        horizontalConstraints.forEach { $0.isActive = false }
        verticalConstraints.forEach { $0.isActive = true }
        
        horizontalStackView.isHidden = true
        verticalStackView.isHidden = false
        
        verticalStackView.removeAllArrangedSubviews()
        verticalStackView.addArrangedSubviews(attachmentViews)
    }
}
