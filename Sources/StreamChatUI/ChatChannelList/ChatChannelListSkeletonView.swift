//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// Default implementation for the loading state view, using a similar layout of the Channel list animating each UI element in the cells with a shimmer.
open class ChatChannelListSkeletonView: _View, ThemeProvider, UITableViewDataSource {
    open private(set) lazy var tableView = UITableView().withoutAutoresizingMaskConstraints

    open var numberOfCells = 15

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
        
        addSubview(tableView)
        tableView.pin(anchors: [.leading, .trailing, .bottom], to: self)
        tableView.pin(anchors: [.top], to: safeAreaLayoutGuide)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfCells
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(with: ChatChannelListCollectionViewSkeletonCell.self, for: indexPath)
    }
}
