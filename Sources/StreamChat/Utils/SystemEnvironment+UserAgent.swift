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
    private static var info: [String: Any] { Bundle.main.infoDictionary ?? [:] }
    private static var appName: String {
        ((info["CFBundleDisplayName"] ?? info[kCFBundleIdentifierKey as String]) as? String) ?? "App name unavailable"
    }

    private static var appVersion: String { (info["CFBundleShortVersionString"] as? String) ?? "0" }
    
    private static var model: String {
        #if os(iOS)
        return deviceModelName
        #elseif os(macOS)
        return getMacModelIdentifier()
        #endif
    }

    private static var osVersion: String {
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }
    
    private static var os: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "MacOS"
        #endif
    }
    
    private static var scale: String {
        #if os(iOS)
        return String(format: "%0.2f", UIScreen.main.scale)
        #elseif os(macOS)
        return "1.00"
        #endif
    }
    
    static var userAgent: String {
        "\(appName)/\(appVersion) (\(model); \(os) \(osVersion); Scale/\(scale))"
    }
    
    #if os(macOS)
    static func getMacModelIdentifier() -> String {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        var model = "MacOS device"
        
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data,
            let deviceModelString = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) {
            model = deviceModelString
        }
        
        IOObjectRelease(service)
        return model
    }
    #endif
}
