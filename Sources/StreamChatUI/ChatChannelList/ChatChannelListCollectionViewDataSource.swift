//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

open class ChatChannelListCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        UICollectionViewCell()
    }
}
