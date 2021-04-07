//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class MessageCollectionView: UICollectionView {
    func dequeueReusableCell(
        withReuseIdentifier identifier: String,
        layoutOptions: ChatMessageLayoutOptions,
        for indexPath: IndexPath
    ) -> UICollectionViewCell {
        // TODO: implement
        let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! MessageCell<NoExtraData>
        
        if cell.content == nil { // this is wrong :)
            cell.setUpLayout(options: layoutOptions)
        }
        
        return cell
    }
}
