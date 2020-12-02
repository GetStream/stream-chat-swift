//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class СhatMessageCollectionViewCell<ExtraData: UIExtraDataTypes>: UICollectionViewCell, UIConfigProvider {
    struct Layout {}
    var layout: Layout? {
        didSet { setNeedsLayout() }
    }

    var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContent() }
    }
    
    // MARK: - Subviews

    public private(set) lazy var messageView = uiConfig.messageList.messageContentView.init().withoutAutoresizingMaskConstraints
    
    // MARK: - Lifecycle

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil else { return }

        setUpLayout()
        updateContent()
    }

    func setUpLayout() {
        contentView.addSubview(messageView)

        NSLayoutConstraint.activate([
            messageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            messageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
    }

    func updateContent() {
        messageView.message = message
    }

    // MARK: - Overrides

    override func prepareForReuse() {
        super.prepareForReuse()

        message = nil
    }
    
    override func preferredLayoutAttributesFitting(
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

class СhatIncomingMessageCollectionViewCell<ExtraData: UIExtraDataTypes>: СhatMessageCollectionViewCell<ExtraData> {
    static var reuseId: String { String(describing: self) }

    override func setUpLayout() {
        super.setUpLayout()

        messageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    }
}

class СhatOutgoingMessageCollectionViewCell<ExtraData: UIExtraDataTypes>: СhatMessageCollectionViewCell<ExtraData> {
    static var reuseId: String { String(describing: self) }

    override func setUpLayout() {
        super.setUpLayout()

        messageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}

class СhatMessageCollectionViewCellLayoutManager<ExtraData: UIExtraDataTypes> {
    /// As all mad scientists we need lab rats to conduct our experiments.
    /// But as we know, lab rats never survive to the end.
    private let labRat: СhatMessageCollectionViewCell<ExtraData> = {
        let dumbContainer = UIView()
        let rat = СhatMessageCollectionViewCell<ExtraData>(frame: .zero)
        /// fire didMoveToSuperview
        dumbContainer.addSubview(rat)
        return rat
    }()

    func heightForCell(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGFloat {
        sizeForCell(with: data, limitedBy: width).height
    }

    func sizeForCell(with data: _ChatMessageGroupPart<ExtraData>, limitedBy width: CGFloat) -> CGSize {
        let attributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
        attributes.frame = CGRect(x: 0, y: 0, width: width, height: 3000)
        labRat.message = data
        let preference = labRat.preferredLayoutAttributesFitting(attributes)
        return preference.frame.size
    }

    func layoutForCell(
        with data: _ChatMessageGroupPart<ExtraData>,
        limitedBy width: CGFloat
    ) -> СhatMessageCollectionViewCell<ExtraData>.Layout {
        СhatMessageCollectionViewCell.Layout()
    }
}
