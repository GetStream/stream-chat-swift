//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

class StreamLayoutAttributes: UICollectionViewLayoutAttributes {
    var layoutOptions: ChatMessageLayoutOptions?
    var appearingOptions: ChatMessageLayoutOptions?
    var disappearingOptions: ChatMessageLayoutOptions?
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! StreamLayoutAttributes
        copy.layoutOptions = layoutOptions
        copy.appearingOptions = appearingOptions
        copy.disappearingOptions = disappearingOptions
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let customAttributes = object as? StreamLayoutAttributes {
            if layoutOptions != customAttributes.layoutOptions
                || appearingOptions != appearingOptions
                || disappearingOptions != disappearingOptions
            { return false }
            return super.isEqual(object)
        } else {
            return false
        }
    }
}
