//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays a collection of image attachments
public typealias ChatMessageComposerImageAttachmentsView = _ChatMessageComposerImageAttachmentsView<NoExtraData>

/// A view that displays a collection of image attachments
open class _ChatMessageComposerImageAttachmentsView<ExtraData: ExtraDataTypes>: _View,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    /// The image attachment item size. Can be overridden in `setUpLayout()`.
    private var imagePreviewItemSize: CGSize = .init(width: 100, height: 100)

    /// The images data source.
    public var content: [UIImage] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The closure handler when an image attachment has been removed.
    public var didTapRemoveItemButton: ((Int) -> Void)?

    /// The collection view layout of the image attachments collection view.
    public private(set) lazy var flowLayout: UICollectionViewFlowLayout = uiConfig
        .messageComposer
        .imageAttachmentsCollectionViewLayout.init()

    /// The collection view of image attachments.
    public private(set) lazy var collectionView: UICollectionView = uiConfig
        .messageComposer
        .imageAttachmentsCollectionView
        .init(frame: .zero, collectionViewLayout: self.flowLayout)
        .withoutAutoresizingMaskConstraints

    override public func defaultAppearance() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }
    
    override open func setUp() {
        super.setUp()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            uiConfig.messageComposer.imageAttachmentCollectionViewCell.self,
            forCellWithReuseIdentifier: uiConfig.messageComposer.imageAttachmentCollectionViewCell.reuseId
        )
    }
    
    override open func setUpLayout() {
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = imagePreviewItemSize
        flowLayout.sectionInset = layoutMargins

        embed(collectionView, insets: .init(top: layoutMargins.top, leading: 0, bottom: layoutMargins.bottom, trailing: 0))
        collectionView.heightAnchor.pin(equalToConstant: imagePreviewItemSize.height).isActive = true
    }
    
    override open func updateContent() {
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        content.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(
                withReuseIdentifier: uiConfig.messageComposer.imageAttachmentCollectionViewCell.reuseId,
                for: indexPath
            ) as? _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>
        else {
            return UICollectionViewCell()
        }

        cell.uiConfig = uiConfig
        cell.imageAttachmentView.imageView.image = content[indexPath.row]
        cell.imageAttachmentView.discardButtonHandler = { [weak self] in
            self?.didTapRemoveItemButton?(indexPath.row)
        }
        
        return cell
    }
}
