//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatDocumentAttachmentsCollectionViewLayout: UICollectionViewFlowLayout {
    open var itemHeight: CGFloat = 70
    
    override public required init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override open func prepare() {
        super.prepare()
        let width = (collectionView?.bounds.width ?? 0) - sectionInset.left - sectionInset.right
        itemSize = .init(width: width, height: itemHeight)
    }
}
