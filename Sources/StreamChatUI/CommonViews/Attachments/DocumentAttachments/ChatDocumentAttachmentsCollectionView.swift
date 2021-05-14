//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatDocumentAttachmentsCollectionView = _ChatDocumentAttachmentsCollectionView<NoExtraData>

open class _ChatDocumentAttachmentsCollectionView<ExtraData: ExtraDataTypes>: _View,
    ComponentsProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    // MARK: - Properties
    
    open var documentPreviewItemHeight: CGFloat = 70
    open var maxNumberOfVisibleDocuments: Int = 3
    
    public var content: [AttachmentPreview] = [] {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    public var didTapRemoveItemButton: ((Int) -> Void)?
    
    override open var intrinsicContentSize: CGSize {
        let numberOfVisibleItems = CGFloat(min(content.count, maxNumberOfVisibleDocuments))
        let itemsHeight = documentPreviewItemHeight * numberOfVisibleItems
        let spacings = flowLayout.minimumInteritemSpacing * (numberOfVisibleItems - 1)
        let height = itemsHeight + spacings + layoutMargins.top + layoutMargins.bottom
        
        return .init(
            width: UIView.noIntrinsicMetric,
            height: height
        )
    }
    
    public private(set) lazy var flowLayout = components
        .messageComposer
        .documentAttachmentsFlowLayout
        .init()
    
    // MARK: - Subviews
    
    public private(set) lazy var collectionView: UICollectionView = .init(frame: .zero, collectionViewLayout: flowLayout)
    
    // MARK: - Public
    
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
            _ChatDocumentAttachmentsCollectionViewCell<ExtraData>.self,
            forCellWithReuseIdentifier: _ChatDocumentAttachmentsCollectionViewCell<ExtraData>.reuseId
        )
    }
    
    override open func setUpLayout() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        embed(collectionView)
        
        flowLayout.itemHeight = documentPreviewItemHeight
        flowLayout.sectionInset = layoutMargins
    }
    
    override open func updateContent() {
        collectionView.isScrollEnabled = content.count > maxNumberOfVisibleDocuments ? true : false
        collectionView.reloadData()
    }

    // MARK: - UICollectionView
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        content.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(
                withReuseIdentifier: _ChatDocumentAttachmentsCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as? _ChatDocumentAttachmentsCollectionViewCell<ExtraData>
        else { return UICollectionViewCell() }
        
        cell.documentAttachmentView.fileNameLabel.text = content[indexPath.row].name
        cell.documentAttachmentView.fileIconImageView.image = content[indexPath.row].image
        cell.documentAttachmentView.fileSizeLabel.text =
            AttachmentFile.sizeFormatter.string(fromByteCount: content[indexPath.row].size)
        
        cell.documentAttachmentView.discardButtonHandler = { [weak self] in self?.didTapRemoveItemButton?(indexPath.row) }
        return cell
    }
}
