//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The header reusable view of the suggestion collection view.
open class ChatSuggestionsCollectionReusableView: UICollectionReusableView,
    ComponentsProvider {
    /// The reuse identifier of the reusable header view.
    open class var reuseId: String { String(describing: self) }

    /// The suggestions header view.
    open lazy var suggestionsHeader: ChatSuggestionsHeaderView = {
        let header = components.suggestionsHeaderView.init().withoutAutoresizingMaskConstraints
        embed(header)
        return header
    }()
}
