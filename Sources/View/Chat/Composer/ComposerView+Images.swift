//
//  ComposerView+Images.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxKeyboard

// MARK: - Images Collection View

extension ComposerView: UICollectionViewDataSource {
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
        collectionView.register(cellType: AttachmentCollectionViewCell.self)
        collectionView.snp.makeConstraints { $0.height.equalTo(CGFloat.composerAttachmentsHeight) }
        
        return collectionView
    }
    
    func addImage(_ item: UploaderItem) {
        guard let uploader = uploader else {
            return
        }
        
        uploader.upload(item: item)
        updateImagesCollectionView()
        
        if !isUploaderImagesEmpty {
            imagesCollectionView.scrollToItem(at: .item(0), at: .right, animated: false)
        }
    }
    
    func updateImagesCollectionView() {
        imagesCollectionView.reloadData()
        imagesCollectionView.isHidden = isUploaderImagesEmpty
        updateTextHeightIfNeeded()
        updateSendButton()
        updateStyleState()
        updateToolBarHeight()
    }
    
    var isUploaderImagesEmpty: Bool {
        return (uploader?.items.firstIndex(where: { $0.type != .file })) == nil
    }
    
    var imagesItems: [UploaderItem] {
        return uploader?.items.filter({ $0.type != .file }) ?? []
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isUploaderImagesEmpty ? 0 : imagesItems.count + (imagesAddAction == nil ? 0 : 1)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as AttachmentCollectionViewCell
        
        if indexPath.item == 0, let imagesAddAction = imagesAddAction {
            cell.updatePlusButton(tintColor: style?.textColor, action: imagesAddAction)
            return cell
        }
        
        let imageIndex = indexPath.item - (imagesAddAction == nil ? 0 : 1)
        let imagesItems = self.imagesItems
        
        guard imageIndex < imagesItems.count else {
            return .unused
        }
        
        let item = imagesItems[imageIndex]
        cell.imageView.image = item.image
        
        cell.updateRemoveButton(tintColor: style?.textColor) { [weak self] in
            if let self = self {
                self.uploader?.remove(item)
                self.updateImagesCollectionView()
            }
        }
        
        if item.attachment == nil, item.error == nil {
            cell.updateForProgress(item.lastProgress)
            
            item.uploadingCompletion
                .observeOn(MainScheduler.instance)
                .subscribe(onError: { [weak cell] _ in cell?.updateForError() },
                           onCompleted: { [weak cell] in cell?.updateForProgress(1) })
                .disposed(by: cell.disposeBag)
            
            item.uploadingProgress
                .do(onError: { [weak cell] error in cell?.updateForError() },
                    onDispose: { [weak cell, weak item] in
                        if item?.error == nil {
                            cell?.updateForProgress(1)
                        } else {
                            cell?.updateForError()
                        }
                })
                .bind(to: cell.progressView.rx.progress)
                .disposed(by: cell.disposeBag)
            
        } else if item.error != nil {
            cell.updateForError()
        }
        
        return cell
    }
}
