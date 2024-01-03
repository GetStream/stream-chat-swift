//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Atlantis
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

    // This function is called from `DemoAppCoordinator` before the Chat UI is created
    static func setInternalConfiguration() {
        configureAtlantisIfNeeded()
    }

    // HTTP and WebSocket Proxy with Proxyman.app
    private static func configureAtlantisIfNeeded() {
        if AppConfig.shared.demoAppConfig.isAtlantisEnabled {
            Atlantis.start()
        } else {
            Atlantis.stop()
        }
    }

    // Performance tracker
    static func showPerformanceTracker() {
        guard StreamRuntimeCheck.isStreamInternalConfiguration else { return }
        // PerformanceMonitor seems to have a bug where it cannot find the hierarchy when trying to place its view
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance]
            PerformanceMonitor.shared().start()
        }
    }
}
