//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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

    /// The maximum number of files visible before scrolling is enabled.
    open var maxNumberOfVisibleFiles: Int = 3

    /// The closure handler when an attachment has been removed.
    open var didTapRemoveItemButton: ((Int) -> Void)?

    /// The scroll view that contains the horizontal and vertical stacks.
    open private(set) lazy var scrollView: UIScrollView = UIScrollView()
        .withoutAutoresizingMaskConstraints

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

    /// The constraints of the attachments horizontal stack.
    open private(set) var horizontalConstraints: [NSLayoutConstraint] = []

    /// The constraints of the attachments vertical stack.
    open private(set) var verticalConstraints: [NSLayoutConstraint] = []
    
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
        
        scrollView.heightAnchor.pin(greaterThanOrEqualToConstant: 0).isActive = true
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
        // Re-enable scroll
        scrollView.isScrollEnabled = true
        
        horizontalConstraints.forEach { $0.isActive = true }
        verticalConstraints.forEach { $0.isActive = false }
        
        horizontalStackView.isHidden = false
        verticalStackView.isHidden = true
        
        horizontalStackView.removeAllArrangedSubviews()
        horizontalStackView.addArrangedSubviews(attachmentViews)
    }
    
    open func setupVerticalStackView() {
        // Disable scroll when not needed
        scrollView.isScrollEnabled = content.count > maxNumberOfVisibleFiles

        horizontalConstraints.forEach { $0.isActive = false }
        verticalConstraints.forEach { $0.isActive = true }
        
        horizontalStackView.isHidden = true
        verticalStackView.isHidden = false
        
        verticalStackView.removeAllArrangedSubviews()
        verticalStackView.addArrangedSubviews(attachmentViews)
    }
}
