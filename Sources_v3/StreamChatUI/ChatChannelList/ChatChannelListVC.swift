//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListVC<ExtraData: UIExtraDataTypes>: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate {
    // MARK: - Properties
    
    public var controller: _ChatChannelListController<ExtraData>!
    public var uiConfig: UIConfig<ExtraData> = .default
    public var didSelectChannel: (_ChatChannel<ExtraData>) -> Void = { _ in }
    
    private lazy var collectionView: ChatChannelListCollectionView = {
        let layout = uiConfig.channelList.channelCollectionLayout.init()
        let collection = uiConfig.channelList.channelCollectionView.init(layout: layout)
        collection.register(uiConfig.channelList.channelViewCell.self, forCellWithReuseIdentifier: "Cell")
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.embed(collectionView)
        
        controller.setDelegate(self)
        controller.synchronize()
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.channels.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for: indexPath
        ) as! ChatChannelListCollectionViewCell<ExtraData>
    
        cell.uiConfig = uiConfig
        cell.channelView.channel = controller.channels[indexPath.row]
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = controller.channels[indexPath.row]
        didSelectChannel(channel)
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        guard bottomEdge >= scrollView.contentSize.height else { return }
        controller.loadNextChannels()
    }
}

// MARK: - _ChatChannelListControllerDelegate

extension ChatChannelListVC: _ChatChannelListControllerDelegate {
    public func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) {
        collectionView.reloadData()
    }
}
