//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

private class BundleIdentifyingClass {}

extension Bundle {
    static var streamChatUI: Bundle {
        // We're using `resource_bundles` to export our resources in the podspec file
        // (See https://guides.cocoapods.org/syntax/podspec.html#resource_bundles)
        // since we need to support building pod as a static library.
        // This attribute causes cocoapods to build a resource bundle and put all our resources inside, during `pod install`
        // But this bundle exists only for cocoapods builds, and for other methods (Carthage, git submodule) we directly export
        // assets.
        // So we need this compiler check to decide which bundle to use.
        // See https://github.com/GetStream/stream-chat-swift/issues/774
        #if COCOAPODS
        return Bundle(for: BundleIdentifyingClass.self)
            .url(forResource: "StreamChatUIResources", withExtension: "bundle")
            .flatMap(Bundle.init(url:))!
        #elseif SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleIdentifyingClass.self)
        #endif
    }
}
