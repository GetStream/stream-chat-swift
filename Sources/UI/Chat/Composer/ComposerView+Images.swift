//
//  ComposerView+Images.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import RxSwift
import RxCocoa

// MARK: - Images Collection View

extension ComposerView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func setupImagesCollectionView() -> UICollectionView {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.itemSize = CGSize(width: .composerAttachmentSize, height: .composerAttachmentSize)
        collectionViewLayout.minimumLineSpacing = .composerCornerRadius / 2
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.sectionInset = UIEdgeInsets(top: 0, left: .composerCornerRadius, bottom: 0, right: .composerCornerRadius)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.isHidden = true
        collectionView.backgroundColor = backgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellType: AttachmentCollectionViewCell.self)
        collectionView.snp.makeConstraints { $0.height.equalTo(CGFloat.composerAttachmentsHeight) }
        
        return collectionView
    }
    
    /// Add an image upload item for message attachments.
    ///
    /// - Parameter item: an image upload item.
    public func addImageUploaderItem(_ item: UploadingItem) {
        guard let uploadManager = uploadManager else {
            return
        }
        
        uploadManager.add(item: item)
        updateImagesCollectionView()
        
        if !uploadManager.images.isEmpty {
            imagesCollectionView.scrollToItem(at: .item(0), at: .right, animated: false)
        }
    }
    
    func updateImagesCollectionView() {
        imagesCollectionView.reloadData()
        imagesCollectionView.isHidden = uploadManager?.images.isEmpty ?? true
        updateTextHeightIfNeeded()
        updateSendButton()
        updateStyleState()
        updateToolbarIfNeeded()
    }
    
    private func uploaderItem(at indexPath: IndexPath) -> UploadingItem? {
        uploadManager?.images[safe: (indexPath.item - (imagesAddAction == nil ? 0 : 1))]
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let uploadManager = uploadManager, !uploadManager.images.isEmpty else {
            return 0
        }
        
        return uploadManager.images.count + (imagesAddAction == nil ? 0 : 1)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as AttachmentCollectionViewCell
        
        guard let item = uploaderItem(at: indexPath) else {
            if indexPath.item == 0, let imagesAddAction = imagesAddAction {
                cell.updatePlusButton(tintColor: style?.textColor, action: imagesAddAction)
                return cell
            }
            
            return .unused
        }
        
        cell.imageView.image = item.image
        
        cell.updateRemoveButton(tintColor: style?.textColor) { [weak self] in
            if let self = self {
                self.uploadManager?.remove(item)
                self.updateImagesCollectionView()
                self.updateSendButton()
            }
        }
        
        if item.attachment == nil {
            cell.updateForProgress(item.lastProgress)
            
            uploadManager?.startUploading(item: item)
                .observeOn(MainScheduler.instance)
                .do(onError: { [weak cell] error in cell?.updateForError() },
                    onCompleted: { [weak self, weak cell] in
                        cell?.updateForProgress(1)
                        self?.updateSendButton()
                    },
                    onDispose: { [weak cell, weak item] in
                        if item?.error == nil {
                            cell?.updateForProgress(1)
                        } else {
                            cell?.updateForError()
                        }
                })
                .map { $0.progress }
                .catchErrorJustReturn(0)
                .bind(to: cell.progressView.rx.progress)
                .disposed(by: cell.disposeBag)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        if let cell = cell as? AttachmentCollectionViewCell,
            let item = uploaderItem(at: indexPath),
            let gifData = item.gifData {
            cell.startGifAnimation(with: gifData)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplaying cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        if let cell = cell as? AttachmentCollectionViewCell {
            cell.removeGifAnimation()
        }
    }
}
