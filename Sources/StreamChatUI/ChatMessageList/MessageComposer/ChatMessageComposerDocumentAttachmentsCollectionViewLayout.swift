//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

internal class ChatMessageComposerDocumentAttachmentsCollectionViewLayout: UICollectionViewFlowLayout {
    internal var itemHeight: CGFloat = 70
    
    override internal required init() {
        super.init()
    }

    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override internal func prepare() {
        super.prepare()
        let width = (collectionView?.bounds.width ?? 0) - sectionInset.left - sectionInset.right
        itemSize = .init(width: width, height: itemHeight)
    }
}
