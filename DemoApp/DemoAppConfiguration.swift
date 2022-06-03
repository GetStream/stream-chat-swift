//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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

    private static var isStreamInternalConfiguration: Bool {
        ProcessInfo.processInfo.environment["STREAM_DEV"] != nil
    }

    static func setInternalConfiguration() {
        func enableMessageDiffingIfNeeded() {
            StreamChatWrapper.shared.setMessageDiffingEnabled(isStreamInternalConfiguration)
        }

        func setupInternalConfiguration() {
            StreamRuntimeCheck.assertionsEnabled = isStreamInternalConfiguration
            StreamRuntimeCheck._isLazyMappingEnabled = !isStreamInternalConfiguration

            configureAtlantisIfNeeded()
            trackPerformanceIfNeeded()
        }

        // HTTP and WebSocket Proxy with Proxyman.app
        func configureAtlantisIfNeeded() {
            if isStreamInternalConfiguration || AppConfig.shared.demoAppConfig.isAtlantisEnabled {
                Atlantis.start()
            } else {
                Atlantis.stop()
            }
        }

        // Performance tracker
        func trackPerformanceIfNeeded() {
            if isStreamInternalConfiguration {
                PerformanceMonitor.shared().performanceViewConfigurator.options = [.performance]
                PerformanceMonitor.shared().start()
            }
        }
    }
}
