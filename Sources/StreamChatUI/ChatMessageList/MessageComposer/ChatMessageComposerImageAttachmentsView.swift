//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerImageAttachmentsView = _ChatMessageComposerImageAttachmentsView<NoExtraData>

internal class _ChatMessageComposerImageAttachmentsView<ExtraData: ExtraDataTypes>: _View,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    // MARK: - Properties
    
    internal var imagePreviewItemSize: CGSize = .init(width: 100, height: 100)
    
    internal var images: [UIImage] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    internal var didTapRemoveItemButton: ((Int) -> Void)?
    
    override internal var intrinsicContentSize: CGSize {
        let height = imagePreviewItemSize.height + layoutMargins.top + layoutMargins.bottom
        return .init(
            width: UIView.noIntrinsicMetric,
            height: height
        )
    }
    
    internal private(set) lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    // MARK: - Subviews
    
    internal private(set) lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: flowLayout)
    
    // MARK: - internal
    
    override internal func defaultAppearance() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }
    
    override internal func setUp() {
        super.setUp()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.reuseId
        )
    }
    
    override internal func setUpLayout() {
        embed(collectionView)
        
        flowLayout.itemSize = imagePreviewItemSize
        flowLayout.sectionInset = layoutMargins
    }
    
    override internal func updateContent() {
        collectionView.reloadData()
    }

    // MARK: - UICollectionView
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(
                withReuseIdentifier: _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as? _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>
        else { return UICollectionViewCell() }
        
        cell.imageView.image = images[indexPath.row]
        cell.discardButtonHandler = { [weak self] in self?.didTapRemoveItemButton?(indexPath.row) }
        
        return cell
    }
}
