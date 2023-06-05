//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Atlantis
import Foundation
import GDPerformanceView_Swift
import Sentry
import StreamChat

enum DemoAppConfiguration {
    static func configureSentry() {
        #if RELEASE
        // We're tracking Crash Reports / Issues from the Demo App to keep improving the SDK
        SentrySDK.start { options in
            options.dsn = "https://75b1074a38704dc0923d9de56fe1e1d4@o389650.ingest.sentry.io/6379288"
            options.tracesSampleRate = 1.0
        }
        #endif
    }

    // MARK: Internal configuration

    static var isStreamInternalConfiguration: Bool {
        ProcessInfo.processInfo.environment["STREAM_DEV"] != nil
    }

    // This function is called from `DemoAppCoordinator` before the Chat UI is created
    static func setInternalConfiguration() {
        StreamRuntimeCheck.assertionsEnabled = isStreamInternalConfiguration
        StreamRuntimeCheck._isBackgroundMappingEnabled = false
        AppConfig.shared.demoAppConfig.isTokenRefreshEnabled = isStreamInternalConfiguration

        configureAtlantisIfNeeded()
    }

    // HTTP and WebSocket Proxy with Proxyman.app
    private static func configureAtlantisIfNeeded() {
        if isStreamInternalConfiguration || AppConfig.shared.demoAppConfig.isAtlantisEnabled {
            Atlantis.start()
        } else {
            Atlantis.stop()
        }
    }

    // Performance tracker
    static func showPerformanceTracker() {
        guard isStreamInternalConfiguration else { return }
        // PerformanceMonitor seems to have a bug where it cannot find the hierarchy when trying to place its view
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance]
            PerformanceMonitor.shared().start()
        }
    }
}
