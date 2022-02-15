//
//  AttachmentListContainerView.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 10/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import CoreGraphics
import Nuke
import StreamChatUI
import StreamChat
import CoreData

public class AttachmentListContainerView: UIView {
    
    public var lblEmptyMessage = UILabel()
    
    public var collectionView: UICollectionView?
    
    public var arrChatMessages = [ChatMessage]()
    
    public var attachmentType = AttachmentType.unknown
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        //custom initialization
        
        collectionView?.removeFromSuperview()
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.scrollDirection = .vertical
        
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: flowLayout)
        
        collectionView?.register(UINib(nibName: AttachmentListCollectionViewCell.reuseID, bundle: nil), forCellWithReuseIdentifier: AttachmentListCollectionViewCell.reuseID)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = .clear
        
        addSubview(collectionView!)
        updateChildViewContraint(childView: collectionView)
        
        addSubview(lblEmptyMessage)
        lblEmptyMessage.font = UIFont.systemFont(ofSize: 15)
        lblEmptyMessage.textColor = Appearance.default.colorPalette.subtitleText
        lblEmptyMessage.frame = bounds
        lblEmptyMessage.textAlignment = .center
        //updateChildViewInCenter(childView: lblEmptyMessage, constant: 300)
    }
    
    public func setupChatMessage(_ arr: [ChatMessage]) {
        self.arrChatMessages = arr
        self.collectionView?.reloadData()
        self.lblEmptyMessage.text = arrChatMessages.isEmpty ? "No media available." : ""
    }
    public func updateEmptyMessage() {
        switch attachmentType {
        case .image:
            self.lblEmptyMessage.text = arrChatMessages.isEmpty ? "No media available." : ""
        case .file:
            self.lblEmptyMessage.text = "No file available"
        case .linkPreview:
            self.lblEmptyMessage.text = "No link available"
        default:
            self.lblEmptyMessage.text = ""
        }
    }
}

// MARK: - COLLECTION VIEW

extension AttachmentListContainerView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrChatMessages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID = AttachmentListCollectionViewCell.reuseID
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath as IndexPath) as? AttachmentListCollectionViewCell
        cell?.backgroundColor = .clear
        cell?.attachmentImageView.layer.cornerRadius = 8.0
        //cell?.attachmentImageView.image =
        
//        let images = arrChatMessages[indexPath.item].imageAttachments.map(\.asAnyAttachment)
//        
        let data = arrChatMessages[indexPath.item].imageAttachments.first
        
        if let imageURL = data?.imageURL {
            Nuke.loadImage(with: imageURL, into: cell!.attachmentImageView)
        }
        return cell!
    }
    
    
    
}
