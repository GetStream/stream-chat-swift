//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelUserDetailCollectionViewLayout: UICollectionViewFlowLayout {
    // MARK: - Init
    
    override public init() {
        super.init()
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Overrides
    
    override open func prepare() {
        super.prepare()
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: 56
        )
    }
    
    // MARK: - Private
    
    private func setup() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }
}
