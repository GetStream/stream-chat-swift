//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class MessageCell<ExtraData: ExtraDataTypes>: _CollectionViewCell {
    static var reuseId: String { "message_cell" }
    
    var content: _ChatMessage<ExtraData>? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    lazy var textView: UITextView = {
        let textView = OnlyLinkTappableTextView()
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    lazy var containerView: ContainerView = ContainerView(axis: .horizontal, alignment: .axisLeading, views: [])
        .withoutAutoresizingMaskConstraints
    
    override func setUpLayout() {
        super.setUpLayout()
        
        contentView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.pin(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            containerView.widthAnchor.pin(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
    }
    
    func setUpLayout(options: ChatMessageLayoutOptions) {
        if options.contains(.text) {
            textView.setContentCompressionResistancePriority(.required, for: .horizontal)
            textView.setContentCompressionResistancePriority(.required, for: .vertical)
            containerView.addArrangedSubview(textView)
        }
    }
    
    override func updateContent() {
        // TODO: this shouldn't intialize the text view
        textView.text = content?.text
    }
    
    override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}
