//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

enum SnapshotVariant: String, Hashable, CaseIterable {
    case small
    case large
    case extraExtraExtraLarge
    
    var traits: UITraitCollection {
        let traits = [
            UITraitCollection(displayScale: 1),
            .iPhoneXr(.portrait),
            contentSizeCategoryTrait,
            userInterfaceStyleTrait
        ]
        return UITraitCollection(traitsFrom: traits)
    }
    
    private var contentSizeCategoryTrait: UITraitCollection {
        switch self {
        case .small:
            return UITraitCollection(preferredContentSizeCategory: .small)
        case .large:
            return UITraitCollection(preferredContentSizeCategory: .large)
        case .extraExtraExtraLarge:
            return UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        }
    }
    
    private var userInterfaceStyleTrait: UITraitCollection {
        switch self {
        case .large, .extraExtraExtraLarge:
            return UITraitCollection(userInterfaceStyle: .light)
        case .small:
            return UITraitCollection(userInterfaceStyle: .dark)
        }
    }
}
