//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class MessageCollectionView: UICollectionView {
    private var identifiers: Set<String> = .init()
    
    func dequeueReusableCell<ExtraData: ExtraDataTypes>(
        layoutOptions: ChatMessageLayoutOptions,
        contentViewClass: MessageContentView<ExtraData>.Type,
        indexPath: IndexPath
    ) -> MessageCell<ExtraData> {
        let reuseIdentifier = "\(MessageCell<ExtraData>.reuseId)_\(layoutOptions.rawValue)_\(contentViewClass)"
        
        // There is no public API to find out
        // if the given `identifier` is registered.
        if !identifiers.contains(reuseIdentifier) {
            identifiers.insert(reuseIdentifier)
            
            register(MessageCell<ExtraData>.self, forCellWithReuseIdentifier: reuseIdentifier)
        }
            
        let cell = dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MessageCell<ExtraData>
        cell.setMessageContentIfNeeded(contentViewClass: contentViewClass, options: layoutOptions)
        return cell
    }
}
