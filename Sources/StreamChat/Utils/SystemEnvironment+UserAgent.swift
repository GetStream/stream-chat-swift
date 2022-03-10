//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import IOKit
#endif

extension SystemEnvironment {
    static let userAgent: String? = {
        guard let info = Bundle.main.infoDictionary,
              let appName = (info["CFBundleDisplayName"] ?? info[kCFBundleIdentifierKey as String]) as? String,
              let appVersion = info[kCFBundleVersionKey as String] as? String
        else {
            return nil
        }

        var model: String
        var os: String

        #if canImport(UIKit)

        var scale = String(format: "%0.2f", UIScreen.main.scale)
        model = UIDevice.current.model
        os = UIDevice.current.systemVersion
        return "\(appName)/\(appVersion) (\(model); iOS \(os); Scale/\(scale))"
        #else

        model = getModelIdentifier() ?? ""
        os = ProcessInfo.processInfo.operatingSystemVersionString
        return "\(appName)/\(appVersion) (\(model); MacOS \(os))"
        #endif
    }()
    
    #if os(macOS)
    private static func getModelIdentifier() -> String? {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        var model: String?
        
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data {
            model = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }
        
        IOObjectRelease(service)
        return model
    }
    #endif
}
