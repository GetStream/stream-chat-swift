//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelListCollectionViewLayout: UICollectionViewFlowLayout {
    
    // MARK: - Init & Deinit
    
    override public init() {
        super.init()
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
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
    }
}
