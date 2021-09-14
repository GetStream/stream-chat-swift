//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import SystemConfiguration

enum ReachabilityError: Error {
    case failedToCreateWithAddress(sockaddr, Int32)
    case failedToCreateWithHostname(String, Int32)
    case unableToSetCallback(Int32)
    case unableToSetDispatchQueue(Int32)
    case unableToGetFlags(Int32)
}

class Reachability {
    typealias NetworkReachable = (Reachability) -> Void
    typealias NetworkUnreachable = (Reachability) -> Void
    
    enum Connection: CustomStringConvertible {
        case unavailable, wifi, cellular
        
        var description: String {
            switch self {
            case .cellular: return "Cellular"
            case .wifi: return "WiFi"
            case .unavailable: return "No Connection"
            }
        }
    }
    
    var whenReachable: NetworkReachable?
    var whenUnreachable: NetworkUnreachable?
    
    /// Set to `false` to force Reachability.connection to .none when on cellular connection (default value `true`)
    var allowsCellularConnection: Bool
    
    var connection: Connection {
        if flags == nil {
            try? setReachabilityFlags()
        }
        
        switch flags?.connection {
        case .unavailable?, nil: return .unavailable
        case .cellular?: return allowsCellularConnection ? .cellular : .unavailable
        case .wifi?: return .wifi
        }
    }
    
    private var isRunningOnDevice: Bool = {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }()
    
    private(set) var notifierRunning = false
    private let reachabilityRef: SCNetworkReachability
    private let reachabilitySerialQueue: DispatchQueue
    private let notificationQueue: DispatchQueue?
    
    private(set) var flags: SCNetworkReachabilityFlags? {
        didSet {
            guard flags != oldValue else { return }
            notifyReachabilityChanged()
        }
    }
    
    required init(
        reachabilityRef: SCNetworkReachability,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) {
        allowsCellularConnection = true
        self.reachabilityRef = reachabilityRef
        reachabilitySerialQueue = DispatchQueue(
            label: "io.getstream.StreamChat.reachability",
            qos: queueQoS,
            target: targetQueue
        )
        self.notificationQueue = notificationQueue
    }
    
    convenience init(
        hostname: String,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) throws {
        guard let ref = SCNetworkReachabilityCreateWithName(nil, hostname) else {
            throw ReachabilityError.failedToCreateWithHostname(hostname, SCError())
        }
        
        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue, notificationQueue: notificationQueue)
    }
    
    convenience init(
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) throws {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)
        
        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            throw ReachabilityError.failedToCreateWithAddress(zeroAddress, SCError())
        }
        
        self.init(reachabilityRef: ref, queueQoS: queueQoS, targetQueue: targetQueue, notificationQueue: notificationQueue)
    }
    
    deinit {
        stopNotifier()
    }
}

extension Reachability {
    // MARK: - *** Notifier methods ***
    
    func startNotifier() throws {
        guard !notifierRunning else { return }
        
        let callback: SCNetworkReachabilityCallBack = { (_, flags, info) in
            guard let info = info else { return }
            
            // `weakifiedReachability` is guaranteed to exist by virtue of our
            // retain/release callbacks which we provided to the `SCNetworkReachabilityContext`.
            let weakifiedReachability = Unmanaged<ReachabilityWeakifier>.fromOpaque(info).takeUnretainedValue()
            
            // The weak `reachability` _may_ no longer exist if the `Reachability`
            // object has since been deallocated but a callback was already in flight.
            weakifiedReachability.reachability?.flags = flags
        }
        
        let weakifiedReachability = ReachabilityWeakifier(reachability: self)
        let opaqueWeakifiedReachability = Unmanaged<ReachabilityWeakifier>.passUnretained(weakifiedReachability).toOpaque()
        
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: UnsafeMutableRawPointer(opaqueWeakifiedReachability),
            retain: { (info: UnsafeRawPointer) -> UnsafeRawPointer in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>
                    .fromOpaque(info)
                _ = unmanagedWeakifiedReachability.retain()
                return UnsafeRawPointer(unmanagedWeakifiedReachability.toOpaque())
            },
            release: { (info: UnsafeRawPointer) -> Void in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>
                    .fromOpaque(info)
                unmanagedWeakifiedReachability.release()
            },
            copyDescription: { (info: UnsafeRawPointer) -> Unmanaged<CFString> in
                let unmanagedWeakifiedReachability = Unmanaged<ReachabilityWeakifier>
                    .fromOpaque(info)
                let weakifiedReachability = unmanagedWeakifiedReachability
                    .takeUnretainedValue()
                let description = weakifiedReachability.reachability?.description ?? "nil"
                return Unmanaged.passRetained(description as CFString)
            }
        )
        
        if !SCNetworkReachabilitySetCallback(reachabilityRef, callback, &context) {
            stopNotifier()
            throw ReachabilityError.unableToSetCallback(SCError())
        }
        
        if !SCNetworkReachabilitySetDispatchQueue(reachabilityRef, reachabilitySerialQueue) {
            stopNotifier()
            throw ReachabilityError.unableToSetDispatchQueue(SCError())
        }
        
        // Perform an initial check
        try setReachabilityFlags()
        
        notifierRunning = true
    }
    
    func stopNotifier() {
        defer { notifierRunning = false }
        
        SCNetworkReachabilitySetCallback(reachabilityRef, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachabilityRef, nil)
    }
    
    var description: String {
        flags?.description ?? "unavailable flags"
    }
}

private extension Reachability {
    func setReachabilityFlags() throws {
        try reachabilitySerialQueue.sync { [weak self] in
            guard let self = self else {
                log.warning("Callback called while self is nil")
                return
            }

            var flags = SCNetworkReachabilityFlags()
            if !SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags) {
                self.stopNotifier()
                throw ReachabilityError.unableToGetFlags(SCError())
            }
            
            self.flags = flags
        }
    }
    
    func notifyReachabilityChanged() {
        let notify = { [weak self] in
            guard let self = self else { return }
            self.connection != .unavailable ? self.whenReachable?(self) : self.whenUnreachable?(self)
        }
        
        // notify on the configured `notificationQueue`, or the caller's (i.e. `reachabilitySerialQueue`)
        notificationQueue?.async(execute: notify) ?? notify()
    }
}

private extension SCNetworkReachabilityFlags {
    typealias Connection = Reachability.Connection
    
    var connection: Connection {
        guard isReachableFlagSet else { return .unavailable }
        
        // If we're reachable, but not on an iOS device (i.e. simulator), we must be on WiFi
        #if targetEnvironment(simulator)
        return .wifi
        #else
        
        var connection = Connection.unavailable
        
        if !isConnectionRequiredFlagSet {
            connection = .wifi
        }
        
        if isConnectionOnTrafficOrDemandFlagSet {
            if !isInterventionRequiredFlagSet {
                connection = .wifi
            }
        }
        
        if isOnWWANFlagSet {
            connection = .cellular
        }
        
        return connection
        #endif
    }
    
    var isOnWWANFlagSet: Bool {
        #if os(iOS)
        return contains(.isWWAN)
        #else
        return false
        #endif
    }
    
    var isReachableFlagSet: Bool {
        contains(.reachable)
    }
    
    var isConnectionRequiredFlagSet: Bool {
        contains(.connectionRequired)
    }
    
    var isInterventionRequiredFlagSet: Bool {
        contains(.interventionRequired)
    }
    
    var isConnectionOnTrafficFlagSet: Bool {
        contains(.connectionOnTraffic)
    }
    
    var isConnectionOnDemandFlagSet: Bool {
        contains(.connectionOnDemand)
    }
    
    var isConnectionOnTrafficOrDemandFlagSet: Bool {
        !intersection([.connectionOnTraffic, .connectionOnDemand]).isEmpty
    }
    
    var isTransientConnectionFlagSet: Bool {
        contains(.transientConnection)
    }
    
    var isLocalAddressFlagSet: Bool {
        contains(.isLocalAddress)
    }
    
    var isDirectFlagSet: Bool {
        contains(.isDirect)
    }
    
    var isConnectionRequiredAndTransientFlagSet: Bool {
        intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]
    }
    
    var description: String {
        var info = [String]()
        isOnWWANFlagSet ? info.append("WWAN") : ()
        isReachableFlagSet ? info.append("Reachable") : ()
        isConnectionRequiredFlagSet ? info.append("Required") : ()
        isTransientConnectionFlagSet ? info.append("Transient") : ()
        isInterventionRequiredFlagSet ? info.append("InterventionRequired") : ()
        isConnectionOnTrafficFlagSet ? info.append("ConnectionOnTraffic") : ()
        isConnectionOnDemandFlagSet ? info.append("ConnectionOnDemand") : ()
        isLocalAddressFlagSet ? info.append("LocalAddress") : ()
        isDirectFlagSet ? info.append("Direct") : ()
        
        return info.joined(separator: " ")
    }
}

/**
 `ReachabilityWeakifier` weakly wraps the `Reachability` class
 in order to break retain cycles when interacting with CoreFoundation.
 
 CoreFoundation callbacks expect a pair of retain/release whenever an
 opaque `info` parameter is provided. These callbacks exist to guard
 against memory management race conditions when invoking the callbacks.
 
 #### Race Condition
 
 If we passed `SCNetworkReachabilitySetCallback` a direct reference to our
 `Reachability` class without also providing corresponding retain/release
 callbacks, then a race condition can lead to crashes when:
 - `Reachability` is deallocated on thread X
 - A `SCNetworkReachability` callback(s) is already in flight on thread Y
 
 #### Retain Cycle
 
 If we pass `Reachability` to CoreFoundtion while also providing retain/
 release callbacks, we would create a retain cycle once CoreFoundation
 retains our `Reachability` class. This fixes the crashes and his how
 CoreFoundation expects the API to be used, but doesn't play nicely with
 Swift/ARC. This cycle would only be broken after manually calling
 `stopNotifier()` — `deinit` would never be called.
 
 #### ReachabilityWeakifier
 
 By providing both retain/release callbacks and wrapping `Reachability` in
 a weak wrapper, we:
 - interact correctly with CoreFoundation, thereby avoiding a crash.
 See "Memory Management Programming Guide for Core Foundation".
 - don't alter the API of `Reachability.swift` in any way
 - still allow for automatic stopping of the notifier on `deinit`.
 */
private class ReachabilityWeakifier {
    weak var reachability: Reachability?
    init(reachability: Reachability) {
        self.reachability = reachability
    }
}
