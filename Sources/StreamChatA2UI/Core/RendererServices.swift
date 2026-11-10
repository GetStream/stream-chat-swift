//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Host capabilities that catalog functions and components depend on.
///
/// Injecting these instead of calling platform APIs directly keeps formatting
/// and side effecting functions such as `openUrl` deterministic in tests, and
/// lets an app override behaviour (for example to open links in an in-app
/// browser).
@available(iOS 15.0, macOS 12.0, *)
struct RendererServices: Sendable {
    /// Opens a URL outside of the surface, subject to user activation.
    var openUrl: @MainActor @Sendable (URL) -> Void

    /// Returns the current time, used by date formatting functions.
    var now: @Sendable () -> Date

    /// The locale used for number, currency and date formatting.
    var locale: Locale

    /// The time zone used for date formatting.
    var timeZone: TimeZone

    /// Announces a change to assistive technologies, for components whose `accessibility.live` is set.
    var announce: @MainActor @Sendable (String, AccessibilityAttributes.Live) -> Void

    /// The URL an image, video or audio clip loads from, given the one the agent wrote, or `nil`
    /// to not load it.
    var mediaURL: @Sendable (URL) -> URL?

    /// Creates a services container.
    /// Override any member to change renderer behaviour or make it testable.
    init(
        openUrl: @escaping @MainActor @Sendable (URL) -> Void = { RendererServices.openUrlWithSystem($0) },
        now: @escaping @Sendable () -> Date = { Date() },
        locale: Locale = .current,
        timeZone: TimeZone = .current,
        announce: @escaping @MainActor @Sendable (String, AccessibilityAttributes.Live) -> Void = {
            RendererServices.announceWithSystem($0, live: $1)
        },
        mediaURL: @escaping @Sendable (URL) -> URL? = { url in
            ["http", "https"].contains(url.scheme?.lowercased() ?? "") ? url : nil
        }
    ) {
        self.openUrl = openUrl
        self.now = now
        self.locale = locale
        self.timeZone = timeZone
        self.announce = announce
        self.mediaURL = mediaURL
    }

    /// The default services, wired to the current platform.
    static let `default` = RendererServices()

    /// Opens a URL with the platform's default handler.
    /// Used as the default implementation of ``openUrl``.
    @MainActor
    static func openUrlWithSystem(_ url: URL) {
        #if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #else
        a2uiLogger.warning("Opening URLs is not supported on this platform: \(url)")
        #endif
    }

    /// Posts an announcement with the platform's accessibility API.
    /// A `polite` announcement waits for current speech; an `assertive` one interrupts it.
    @MainActor
    static func announceWithSystem(_ text: String, live: AccessibilityAttributes.Live) {
        guard live != .off, !text.isEmpty else { return }
        #if canImport(UIKit) && !os(watchOS)
        let announcement = NSAttributedString(
            string: text,
            attributes: [.accessibilitySpeechQueueAnnouncement: live == .polite]
        )
        UIAccessibility.post(notification: .announcement, argument: announcement)
        #elseif canImport(AppKit)
        guard let window = NSApp?.mainWindow else { return }
        let priority: NSAccessibilityPriorityLevel = live == .assertive ? .high : .medium
        NSAccessibility.post(
            element: window,
            notification: .announcementRequested,
            userInfo: [.announcement: text, .priority: priority.rawValue]
        )
        #endif
    }
}
