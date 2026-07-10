//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Role: Identifiable {
    /// The unique role identifier.
    public var id: String { name }

    /// Whether the role is custom-defined for the application.
    @available(*, deprecated, renamed: "custom")
    public var isCustom: Bool { custom }
}
