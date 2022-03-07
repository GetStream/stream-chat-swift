//
//  CollectionViewGroupUserList.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 07/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

public class CollectionViewGroupUserList: UIView {
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: 70, height: 70)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = .zero
        let collection = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        let cellNib = UINib.init(nibName: CollectionViewCellGroupUsers.reuseID, bundle: nil)
        collection.register(cellNib, forCellWithReuseIdentifier: CollectionViewCellGroupUsers.reuseID)
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundColor = .clear
        return collection
    }()

    public var selectedUsers = [ChatUser]()
    public var callbackSelectedUser: (([ChatUser]) -> Void)?
    public var isRemovreButtonHidden = true
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Functions
    private func setup() {
        collectionView.removeFromSuperview()
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    public func setupUsers(users: [ChatUser]) {
        self.selectedUsers = users
        self.collectionView.reloadData()
        
    }
}
// MARK: - Functions
extension CollectionViewGroupUserList: UICollectionViewDelegate , UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedUsers.count
    }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCellGroupUsers.reuseID, for: indexPath) as? CollectionViewCellGroupUsers else {
            return UICollectionViewCell.init(frame: .zero)
        }
        cell.configCell(user: selectedUsers[indexPath.row])
        cell.removeUserButton.isHidden = self.isRemovreButtonHidden
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.isRemovreButtonHidden == false {
            selectedUsers.remove(at: indexPath.row)
            collectionView.deleteItems(at: [indexPath])
            self.callbackSelectedUser?(selectedUsers)
        }
    }
}
