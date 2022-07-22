//
//  ChatChannelListSkeletonView.swift
//  StreamChat
//
//  Created by Hugo Bernal on 21/07/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatChannelListSkeletonView: _View, ThemeProvider, UITableViewDataSource {

    open private(set) lazy var tableView = UITableView().withoutAutoresizingMaskConstraints

    private let numberOfCells = 30

    override open func setUp() {
        super.setUp()

        isUserInteractionEnabled = false
        
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(
            components.channelListCollectionViewSkeletonCell.self,
            forCellReuseIdentifier: ChatChannelListCollectionViewSkeletonCell.reuseIdentifier
        )
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        embed(tableView, insets: .init(top: 90, leading: 0, bottom: 0, trailing: 0))
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfCells
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(with: ChatChannelListCollectionViewSkeletonCell.self, for: indexPath)
    }
}
