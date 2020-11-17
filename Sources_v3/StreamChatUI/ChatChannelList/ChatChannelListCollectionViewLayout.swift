//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelListCollectionViewLayout: UICollectionViewFlowLayout {
    private var stopObserving: (() -> Void)?
    
    // MARK: - Init & Deinit
    
    override public init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    deinit {
        stopObserving?()
    }
    
    // MARK: - Overrides
    
    override open func prepare() {
        super.prepare()
        
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: 60
        )
    }
    
    // MARK: - Private
    
    private func commonInit() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
        
        subscribeToNotifications()
    }
    
    private func subscribeToNotifications() {
        let center = NotificationCenter.default
        
        center.addObserver(
            self,
            selector: #selector(didChangeContentSizeCategory),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
        
        stopObserving = { [unowned self] in
            center.removeObserver(self)
        }
    }
    
    @objc private func didChangeContentSizeCategory(_ notification: Notification) {
        invalidateLayout()
    }
}
