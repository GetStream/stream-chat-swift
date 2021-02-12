//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

enum SnapshotVariant: String, Hashable, CaseIterable {
    case small
    case large
    case extraExtraExtraLarge
    
    static var userInterfaceStyleCases: [SnapshotVariant] {
        [small, large]
    }
    
    var traits: UITraitCollection {
        var traits = [
            UITraitCollection(displayScale: 1),
            contentSizeCategoryTrait
        ]
        
        if #available(iOS 12.0, *) {
            traits.append(userInterfaceStyleTrait)
        }
        
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
    
    @available(iOS 12.0, *)
    private var userInterfaceStyleTrait: UITraitCollection {
        switch self {
        case .large, .extraExtraExtraLarge:
            return UITraitCollection(userInterfaceStyle: .light)
        case .small:
            return UITraitCollection(userInterfaceStyle: .dark)
        }
    }
}

extension Array where Element == SnapshotVariant {
    static var allCases: [SnapshotVariant] {
        SnapshotVariant.allCases
    }
    
    static var userInterfaceStyleCases: [SnapshotVariant] {
        SnapshotVariant.userInterfaceStyleCases
    }
}
