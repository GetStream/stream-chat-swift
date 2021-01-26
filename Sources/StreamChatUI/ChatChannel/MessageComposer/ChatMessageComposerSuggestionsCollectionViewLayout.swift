//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatMessageComposerSuggestionsCollectionViewLayout: UICollectionViewFlowLayout {
    override public required init() {
        super.init()
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }

    override open func prepare() {
        super.prepare()
        estimatedItemSize = .init(width: collectionView?.bounds.width ?? 0, height: 60)
    }
}
