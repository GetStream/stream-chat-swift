//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// Default implementation for the loading state view, using a similar layout of the Channel list animating each UI element in the cells with a shimmer.
open class ChatChannelListLoadingView: _View, ThemeProvider, UITableViewDataSource {
    open private(set) lazy var tableView = UITableView()
        .withoutAutoresizingMaskConstraints

    /// Int value that determines the number of cells that are layout when the `ChatChannelListLoadingView` is shown.
    open var numberOfCells = 15

    override open func setUp() {
        super.setUp()

        isUserInteractionEnabled = false
        
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(
            ChatChannelListLoadingViewCell.self,
            forCellReuseIdentifier: ChatChannelListLoadingViewCell.reuseIdentifier
        )
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(tableView)
        tableView.pin(anchors: [.leading, .trailing, .bottom], to: self)
        tableView.pin(anchors: [.top], to: safeAreaLayoutGuide)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        tableView.visibleCells.forEach { $0.layoutSubviews() }
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfCells
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(with: ChatChannelListLoadingViewCell.self, for: indexPath)
    }
}
