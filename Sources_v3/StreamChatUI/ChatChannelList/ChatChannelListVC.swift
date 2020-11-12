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
    
    private lazy var layout: ChatChannelListCollectionViewLayout = {
        let layout = uiConfig.channelList.channelCollectionLayout.init()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        return layout
    }()
    
    private lazy var collectionView: ChatChannelListCollectionView = {
        let collection = uiConfig.channelList.channelCollectionView.init(layout: layout)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
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
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = .init(
            width: view.bounds.width,
            height: 70
        )
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.channels.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let channel = controller.channels[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        if let channelView = cell.contentView.subviews.first as? ChatChannelView<ExtraData> {
            channelView.channel = channel
        } else {
            let channelView = uiConfig.channelList.channelView.init(channel: channel, uiConfig: uiConfig)
            cell.contentView.embed(channelView)
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = controller.channels[indexPath.row]
        didSelectChannel(channel)
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard indexPath.row == controller.channels.count - 1 else { return }
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
