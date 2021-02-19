//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelListCollectionViewLayout: UICollectionViewFlowLayout {
    override public init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
        
    override open func prepare() {
        super.prepare()
        
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: 64
        )
    }
        
    open func commonInit() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        
        subscribeToNotifications()
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
