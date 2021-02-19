//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

internal class ChatMessageComposerSuggestionsCollectionViewLayout: UICollectionViewFlowLayout {
    override internal required init() {
        super.init()
        commonInit()
    }

    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }

    override internal func prepare() {
        super.prepare()
        estimatedItemSize = .init(width: collectionView?.bounds.width ?? 0, height: 60)
    }
}
