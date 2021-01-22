//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelListCollectionView: UICollectionView {
    public required init(layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
