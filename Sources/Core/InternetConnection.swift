//
//  InternetConnection.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/07/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import Reachability
import RxSwift

/// The Internect connection manager.
public final class InternetConnection {
    
    /// A shared Internet Connection.
    public static let shared = InternetConnection()
    
    private(set) lazy var reachability = Reachability(hostname: Client.shared.baseURL.wsURL.host ?? "getstream.io")
    private let disposeBag = DisposeBag()
    let offlineModeSubject = BehaviorSubject(value: false)
    private(set) lazy var rxIsAvailable: Observable<Bool> = rx.setupIsAvailable()
    
    /// Forces to offline mode.
    public var offlineMode = false {
        didSet { offlineModeSubject.onNext(offlineMode) }
    }
    
    /// Check if the Internet is available.
    public var isAvailable: Bool {
        offlineMode ? false : (reachability?.connection ?? .none) != .none
    }
    
    /// Stop observing the Internet connection.
    public func stopObserving() {
        reachability?.stopNotifier()
        log("Notifying stopped 🚶‍♂️")
    }
    
    // MARK: Logs
    
    func log(_ message: String) {
        if !Client.shared.logOptions.isEmpty {
            ClientLogger.log("🕸", message)
        }
    }
}
