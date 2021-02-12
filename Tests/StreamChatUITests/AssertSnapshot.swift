//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import XCTest

/// The default view controller size. Simulates an iPhone in portrait mode.
let defaultScreenSize = CGSize(width: 360, height: 700)

/// Snapshot of a view controller. All variants will be tested by default. For each variant, it will take a snapshot.
/// It is recommended to test all trait variants only for view controllers, and for small view components only test
/// the default variant. This is to minimize the amount of pictures stored in the repo.
///
/// - Parameters:
///   - vc: The view controller to be tested.
///   - isEmbeddedInNavigationController: If the view controller should be embedded in a navigation controller.
///   Useful to test the navigation bar.
///   - variants: The variants that a snapshot will be taken. All variants should be tested for a view controller.
///   - screenSize: The size of the view controller.
///   - suffix: When multiple snapshots are recorded from within the same test, the suffix will be added
///   to the name of the snapshot image file to uniquely identify it.
///   - record: True if a new reference should be saved. False by default,
///   so that the newly captured snapshot is compared with the current reference.
func AssertSnapshot(
    _ vc: UIViewController,
    isEmbeddedInNavigationController: Bool = false,
    variants: [SnapshotVariant] = .allCases,
    screenSize: CGSize = defaultScreenSize,
    suffix: String? = nil,
    record: Bool = false,
    line: UInt = #line,
    file: StaticString = #file,
    function: String = #function
) {
    let viewController = isEmbeddedInNavigationController ? UINavigationController(rootViewController: vc) : vc
    variants.forEach { variant in
        assertSnapshot(
            matching: viewController,
            as: .image(size: screenSize, traits: variant.traits),
            named: variant.rawValue + (suffix.map { "." + $0 } ?? ""),
            record: record,
            file: file,
            testName: function,
            line: line
        )
    }
}

/// Snapshot of a view. Used for view components. Only the default variant is tested.
/// To minimize the amount of snapshot pictures saved in the repo, the rest of the variants should
/// be tested in view controllers.
///
/// - Parameters:
///   - view: The component to be tested.
///   - variants: The variants that a snapshot will be taken.
///   Only the light and dark variants should be tested in small components.
///   - suffix: When multiple snapshots are recorded from within the same test, the suffix will be added
///   to the name of the snapshot image file to uniquely identify it.
///   - record: True if a new reference should be saved. False by default,
///   so that the newly captured snapshot is compared with the current reference.
func AssertSnapshot(
    _ view: UIView,
    variants: [SnapshotVariant] = .userInterfaceStyleCases,
    size: CGSize? = nil,
    suffix: String? = nil,
    record: Bool = false,
    line: UInt = #line,
    file: StaticString = #file,
    function: String = #function
) {
    variants.forEach { variant in
        assertSnapshot(
            matching: view,
            as: .image(traits: variant.traits),
            named: variant.rawValue + (suffix.map { "." + $0 } ?? ""),
            record: record,
            file: file,
            testName: function,
            line: line
        )
    }
}
