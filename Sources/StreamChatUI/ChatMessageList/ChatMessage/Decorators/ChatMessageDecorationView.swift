//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A type that describes where a decoration will be placed
public enum ChatMessageDecorationType: Equatable {
    /// A header decoration is being placed above the
    /// cell's content
    case header

    /// A footer decoration is being placed below the
    /// cell's content
    case footer
}

/// The view that displays any header or footer decorations above & below a
/// ChatMessageCell.
open class ChatMessageDecorationView: _View {
    public static var reuseId: String { "\(self)" }
}
