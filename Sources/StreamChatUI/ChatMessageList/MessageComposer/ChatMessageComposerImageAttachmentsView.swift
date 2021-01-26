//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerImageAttachmentsView = _ChatMessageComposerImageAttachmentsView<NoExtraData>

open class _ChatMessageComposerImageAttachmentsView<ExtraData: ExtraDataTypes>: View,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    // MARK: - Properties
    
    open var imagePreviewItemSize: CGSize = .init(width: 100, height: 100)
    
    public var images: [UIImage] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    public var didTapRemoveItemButton: ((Int) -> Void)?
    
    override open var intrinsicContentSize: CGSize {
        let height = imagePreviewItemSize.height + layoutMargins.top + layoutMargins.bottom
        return .init(
            width: UIView.noIntrinsicMetric,
            height: height
        )
    }
    
    public private(set) lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()
    
    // MARK: - Subviews
    
    public private(set) lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: flowLayout)
    
    // MARK: - Public
    
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
            _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData>.reuseId
        )
    }
    
    override open func setUpLayout() {
        embed(collectionView)
        
        flowLayout.itemSize = imagePreviewItemSize
        flowLayout.sectionInset = layoutMargins
    }
    
    override open func updateContent() {
        collectionView.reloadData()
    }

    // MARK: - UICollectionView
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
