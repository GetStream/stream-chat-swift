//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

internal class ChatMessageListCollectionView: UICollectionView {
    internal required init(layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
