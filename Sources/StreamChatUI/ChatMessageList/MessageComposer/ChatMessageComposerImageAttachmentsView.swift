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
    /// The images data source.
    open var content: [AttachmentPreview] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The closure handler when an image attachment has been removed.
    open var didTapRemoveItemButton: ((Int) -> Void)?

    /// The collection view layout of the image attachments collection view.
    open private(set) lazy var flowLayout: UICollectionViewFlowLayout = uiConfig
        .messageComposer
        .imageAttachmentsCollectionViewLayout.init()

    /// The collection view of image attachments.
    open private(set) lazy var collectionView: UICollectionView = uiConfig
        .messageComposer
        .imageAttachmentsCollectionView
        .init(frame: .zero, collectionViewLayout: self.flowLayout)
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
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
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.sectionInset = layoutMargins

        embed(collectionView)
    }
    
    override open func updateContent() {
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        content.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseId = uiConfig.messageComposer.imageAttachmentCollectionViewCell.reuseId
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseId,
            for: indexPath
        ) as! _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>

        cell.uiConfig = uiConfig
        cell.imageAttachmentView.imageView.image = content[indexPath.row].image
        cell.imageAttachmentView.discardButtonHandler = { [weak self] in
            self?.didTapRemoveItemButton?(indexPath.row)
        }
        
        return cell
    }
}
