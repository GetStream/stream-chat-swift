//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import XCTest

/// A Snapshot Variant is a combination of SnapshotTraits,
/// that will result in a snapshot test with multiple UITraitCollection's.
struct SnapshotVariant {
    let snapshotTraits: [SnapshotTrait]
    var snapshotName: String {
        snapshotTraits.map(\.name).joined(separator: ".")
    }

    var traits: UITraitCollection {
        UITraitCollection(traitsFrom: [UITraitCollection(displayScale: 1)] + snapshotTraits.map(\.trait))
    }
}

/// A Snapshot Trait is usually just a combination of a UITraitCollection and it's name.
struct SnapshotTrait {
    let name: String
    let trait: UITraitCollection
}

extension SnapshotVariant {
    // MARK: - Combinations

    static let all: [SnapshotVariant] = {
        [smallDark, defaultLight, extraExtraExtraLargeLight, rightToLeftLayout]
    }()

    static let onlyUserInterfaceStyles: [SnapshotVariant] = {
        [defaultLight, defaultDark]
    }()

    // MARK: - Variants

    static let extraExtraExtraLargeLight: SnapshotVariant = {
        var traits = [extraExtraExtraLargeTrait]
        if #available(iOS 12.0, *) {
            traits.append(lightTrait)
        }
        return SnapshotVariant(snapshotTraits: traits)
    }()

    static let defaultDark: SnapshotVariant = {
        var traits = [defaultTrait]
        if #available(iOS 12.0, *) {
            traits.append(darkTrait)
        }
        return SnapshotVariant(snapshotTraits: traits)
    }()

    static let defaultLight: SnapshotVariant = {
        var traits = [defaultTrait]
        if #available(iOS 12.0, *) {
            traits.append(lightTrait)
        }
        return SnapshotVariant(snapshotTraits: traits)
    }()

    static let smallDark: SnapshotVariant = {
        var traits = [smallTrait]
        if #available(iOS 12.0, *) {
            traits.append(darkTrait)
        }
        return SnapshotVariant(snapshotTraits: traits)
    }()

    static let rightToLeftLayout = SnapshotVariant(snapshotTraits: [rightToLeftLayoutTrait, defaultTrait])

    // MARK: - Traits

    private static let extraExtraExtraLargeTrait = SnapshotTrait(
        name: "extraExtraExtraLarge",
        trait: UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
    )
    private static let defaultTrait = SnapshotTrait(
        name: "default",
        trait: UITraitCollection(preferredContentSizeCategory: .large)
    )
    private static let smallTrait = SnapshotTrait(
        name: "small",
        trait: UITraitCollection(preferredContentSizeCategory: .small)
    )

    @available(iOS 12.0, *)
    private static let lightTrait = SnapshotTrait(
        name: "light",
        trait: UITraitCollection(userInterfaceStyle: .light)
    )

    @available(iOS 12.0, *)
    private static let darkTrait = SnapshotTrait(
        name: "dark",
        trait: UITraitCollection(userInterfaceStyle: .dark)
    )

    private static let rightToLeftLayoutTrait = SnapshotTrait(
        name: "rightToLeftLayout", trait: .init(layoutDirection: .rightToLeft)
    )
}

extension Array where Element == SnapshotVariant {
    static let all: [SnapshotVariant] = {
        SnapshotVariant.all
    }()

    static let onlyUserInterfaceStyles: [SnapshotVariant] = {
        SnapshotVariant.onlyUserInterfaceStyles
    }()
}
