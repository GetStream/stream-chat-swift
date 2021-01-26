//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatMessageListCollectionView: UICollectionView {
    public required init(layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
