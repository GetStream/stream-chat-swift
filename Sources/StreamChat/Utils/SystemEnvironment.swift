//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

enum SystemEnvironment {
    static let systemName = UIDevice.current.systemName + UIDevice.current.systemVersion
    
    static var deviceModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    static var name: String {
        isAppStore ? "production" : "development"
    }
    
    static var isAppStore: Bool {
        !isSimulator && hasAppStoreReceipt && !hasEmbeddedMobileProvision
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    private static var hasAppStoreReceipt: Bool {
        if let appStoreReceipt = Bundle.main.appStoreReceiptURL {
            return appStoreReceipt.lastPathComponent != "sandboxReceipt"
        }
        
        return false
    }
    
    private static var hasEmbeddedMobileProvision: Bool {
        Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil
    }
    
    static var isExtention: Bool {
        #if TARGET_IS_EXTENSION
        return true
        #else
        return false
        #endif
    }
    
    static var isTests: Bool {
        #if TESTS
        return NSClassFromString("XCTest") != nil
        #else
        return false
        #endif
    }
}
