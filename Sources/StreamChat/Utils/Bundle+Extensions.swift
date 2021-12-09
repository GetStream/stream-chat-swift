//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

private class BundleIdentifyingClass {}

extension Bundle {
    /// A bundle id.
    var id: String? {
        infoDictionary?["CFBundleIdentifier"] as? String
    }
    
    /// A bundle name.
    var name: String? {
        object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
    }
    
    /// Returns `true` if the bundle path has `appex` suffix. When used for the `main` bundle, it can help you to
    /// identify if the executable is an app or an app extension.
    var isAppExtension: Bool {
        let bundlePathExtension: String = bundleURL.pathExtension
        return bundlePathExtension == "appex"
    }

    static var streamChat: Bundle {
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
            .url(forResource: "StreamChat", withExtension: "bundle")
            .flatMap(Bundle.init(url:))!
        #elseif SWIFT_PACKAGE
        return Bundle.module
        #elseif STATIC_LIBRARY
        return Bundle.main
            .url(forResource: "StreamChat", withExtension: "bundle")
            .flatMap(Bundle.init(url:))!
        #else
        return Bundle(for: BundleIdentifyingClass.self)
        #endif
    }
}
