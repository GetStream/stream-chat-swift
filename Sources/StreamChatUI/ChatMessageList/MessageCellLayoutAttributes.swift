//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A custom `UICollectionViewLayoutAttributes` subclass used to store additional
/// information about the layout of the message cell and its context.
open class MessageCellLayoutAttributes: UICollectionViewLayoutAttributes {
    /// The current message layout option of the cell
    open var layoutOptions: ChatMessageLayoutOptions?

    open var previousLayoutOptions: ChatMessageLayoutOptions?

    open var tag: String = " ❌ "

    override open func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! MessageCellLayoutAttributes
        copy.layoutOptions = layoutOptions
        copy.previousLayoutOptions = previousLayoutOptions
        copy.tag = tag
        return copy
    }

    override open func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? MessageCellLayoutAttributes else { return false }

        return layoutOptions == rhs.layoutOptions
            && previousLayoutOptions == rhs.previousLayoutOptions
            && tag == rhs.tag
            && super.isEqual(object)
    }
}
