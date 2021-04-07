//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class MessageListVC<ExtraData: ExtraDataTypes>: _ViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var channelController: _ChatChannelController<ExtraData>!
    
    public private(set) lazy var collectionView: MessageCollectionView = {
        let collection = MessageCollectionView(frame: .zero, collectionViewLayout: ChatMessageListCollectionViewLayout())

        collection.isPrefetchingEnabled = false
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceVertical = true
        collection.keyboardDismissMode = .onDrag
        collection.dataSource = self
        collection.delegate = self

        return collection.withoutAutoresizingMaskConstraints
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.embed(collectionView)
        collectionView.backgroundColor = .white
        
        collectionView.register(MessageCell<ExtraData>.self, forCellWithReuseIdentifier: MessageCell<ExtraData>.reuseId)
        
        channelController.synchronize()
    }
    
    func cellLayoutOptions(for message: _ChatMessage<ExtraData>) -> ChatMessageLayoutOptions {
        // TODO:
        [.text]
    }
    
    func cellReuseIdentifier(for message: _ChatMessage<ExtraData>) -> String {
        MessageCell<ExtraData>.reuseId
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelController.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = channelController.messages[indexPath.item]
        
        let reuseId = cellReuseIdentifier(for: message)
        let layoutOptions = cellLayoutOptions(for: message)
        
        let cell = self.collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseId,
            layoutOptions: layoutOptions,
            for: indexPath
        ) as! MessageCell<ExtraData>
        
        cell.content = message
        
        return cell
    }
}
