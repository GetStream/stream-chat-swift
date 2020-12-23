//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

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
}
