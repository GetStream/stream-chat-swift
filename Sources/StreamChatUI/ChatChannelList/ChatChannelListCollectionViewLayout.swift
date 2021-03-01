//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class ChatChannelListCollectionViewLayout<ExtraData: ExtraDataTypes>: CellSeparatorCollectionViewLayout<ExtraData> {

    override open func commonInit() {
        super.commonInit()
        subscribeToNotifications()
    }

    override open func prepare() {
        super.prepare()
        
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: 64
        )
    }

    open func subscribeToNotifications() {
        let center = NotificationCenter.default
        
        center.addObserver(
            self,
            selector: #selector(didChangeContentSizeCategory),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }
    
    @objc open func didChangeContentSizeCategory(_ notification: Notification) {
        invalidateLayout()
    }
}
