//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerDocumentAttachmentsView = _ChatMessageComposerDocumentAttachmentsView<NoExtraData>

internal class _ChatMessageComposerDocumentAttachmentsView<ExtraData: ExtraDataTypes>: _View,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    // MARK: - Properties
    
    internal var documentPreviewItemHeight: CGFloat = 70
    internal var maxNumberOfVisibleDocuments: Int = 3
    
    internal var documents: [(preview: UIImage, name: String, size: Int64)] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    internal var didTapRemoveItemButton: ((Int) -> Void)?
    
    override internal var intrinsicContentSize: CGSize {
        let numberOfVisibleItems = CGFloat(min(documents.count, maxNumberOfVisibleDocuments))
        let itemsHeight = documentPreviewItemHeight * numberOfVisibleItems
        let spacings = flowLayout.minimumInteritemSpacing * (numberOfVisibleItems - 1)
        let height = itemsHeight + spacings + layoutMargins.top + layoutMargins.bottom
        
        return .init(
            width: UIView.noIntrinsicMetric,
            height: height
        )
    }
    
    internal private(set) lazy var flowLayout = uiConfig
        .messageComposer
        .documentAttachmentsFlowLayout
        .init()
    
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
            _ChatMessageComposerDocumentAttachmentCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: _ChatMessageComposerDocumentAttachmentCollectionViewCell<ExtraData>.reuseId
        )
    }
    
    override internal func setUpLayout() {
        embed(collectionView)
        
        flowLayout.itemHeight = documentPreviewItemHeight
        flowLayout.sectionInset = layoutMargins
    }
    
    override internal func updateContent() {
        collectionView.isScrollEnabled = documents.count > maxNumberOfVisibleDocuments ? true : false
        collectionView.reloadData()
    }

    // MARK: - UICollectionView
    
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        documents.count
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(
                withReuseIdentifier: _ChatMessageComposerDocumentAttachmentCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as? _ChatMessageComposerDocumentAttachmentCollectionViewCell<ExtraData>
        else { return UICollectionViewCell() }
        
        cell.documentAttachmentView.fileNameLabel.text = documents[indexPath.row].name
        cell.documentAttachmentView.fileIconImageView.image = documents[indexPath.row].preview
        cell.documentAttachmentView.fileSizeLabel.text =
            AttachmentFile.sizeFormatter.string(fromByteCount: documents[indexPath.row].size)
        
        cell.documentAttachmentView.discardButtonHandler = { [weak self] in self?.didTapRemoveItemButton?(indexPath.row) }
        return cell
    }
}
