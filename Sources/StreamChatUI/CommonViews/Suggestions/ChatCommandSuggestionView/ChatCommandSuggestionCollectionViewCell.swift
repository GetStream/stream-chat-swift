//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view cell that displays a command.
public typealias ChatCommandSuggestionCollectionViewCell = _ChatCommandSuggestionCollectionViewCell<NoExtraData>

/// A view cell that displays a command.
open class _ChatCommandSuggestionCollectionViewCell: _CollectionViewCell, ComponentsProvider {
    open class var reuseId: String { String(describing: self) }

    public private(set) lazy var commandView = components
        .suggestionsCommandView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.embed(commandView)
    }
}
