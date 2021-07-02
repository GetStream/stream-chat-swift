//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// The collection view layout of the suggestions collection view.
open class ChatSuggestionsCollectionViewLayout: UICollectionViewFlowLayout {
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
