//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import os.signpost
import UIKit

/// `os_signpost` intervals for the two launch-and-open timings that are otherwise
/// measured by hand:
///
/// - **M-LAUNCH** — process start to the first rendered, non-empty channel list.
/// - **M-SETTLE** — a tap that opens a channel to its rendered message list.
///
/// Both are emitted on the `.pointsOfInterest` category, so they appear in Instruments'
/// Points of Interest track under any template. Disabled signposts cost nothing, so this
/// stays compiled in.
///
/// Every `end` is deferred to the completion of the CoreAnimation transaction that puts
/// the content on screen. A data callback fires before layout, so ending there would
/// under-report by at least a frame, and by more when the commit is expensive.
///
/// The launch `end` also carries `total_ms`, measured from the real process start read
/// from the kernel. A signpost cannot be backdated, so the interval itself excludes
/// everything before `didFinishLaunchingWithOptions`; `pre_main_ms` shows that split.
@MainActor
enum PerfSignpost {
    private static let log = OSLog(subsystem: "io.getstream.iOS.ChatDemoApp.perf", category: .pointsOfInterest)

    // MARK: - M-LAUNCH

    private static var launchID: OSSignpostID?
    private static var launchFinished = false

    /// Call as early as possible in the app's lifetime.
    static func beginLaunch() {
        guard launchID == nil, !launchFinished else { return }
        let id = OSSignpostID(log: log)
        launchID = id
        os_signpost(.begin, log: log, name: "M-LAUNCH", signpostID: id, "pre_main_ms=%.1f", preMainMilliseconds)
        // Mirrored to the console so a launch can be timed with nothing attached.
        print(String(format: "[perf] M-LAUNCH begin pre_main_ms=%.1f", preMainMilliseconds))
    }

    /// Call when the channel list has content. Closes on the frame that renders it, once
    /// per launch; later list updates are ignored.
    static func finishLaunchOnNextRenderedFrame(reason: String) {
        guard let id = launchID, !launchFinished else { return }
        launchFinished = true

        afterNextRenderedFrame {
            os_signpost(
                .end,
                log: log,
                name: "M-LAUNCH",
                signpostID: id,
                "%{public}@ total_ms=%.1f pre_main_ms=%.1f",
                reason,
                millisecondsSinceProcessStart,
                preMainMilliseconds
            )
            print(String(format: "[perf] M-LAUNCH end %@ total_ms=%.1f pre_main_ms=%.1f", reason, millisecondsSinceProcessStart, preMainMilliseconds))
        }
    }

    // MARK: - M-SETTLE

    private static var settleID: OSSignpostID?
    private static var settleLabel = ""

    /// Call on the tap that opens a channel or a thread.
    static func beginSettle(_ label: String) {
        // A new tap supersedes one that was backed out of before it settled.
        if let previous = settleID {
            os_signpost(.end, log: log, name: "M-SETTLE", signpostID: previous, "superseded")
        }
        let id = OSSignpostID(log: log)
        settleID = id
        settleLabel = label
        os_signpost(.begin, log: log, name: "M-SETTLE", signpostID: id, "%{public}@", label)
    }

    /// Call when the destination view has its content. Closes on the frame that renders it.
    static func finishSettleOnNextRenderedFrame() {
        guard let id = settleID else { return }
        let label = settleLabel
        settleID = nil
        settleLabel = ""

        afterNextRenderedFrame {
            os_signpost(.end, log: log, name: "M-SETTLE", signpostID: id, "%{public}@", label)
        }
    }

    // MARK: - Timing helpers

    /// Fires once the current CoreAnimation transaction has been committed and rendered.
    private static func afterNextRenderedFrame(_ body: @escaping @MainActor () -> Void) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            MainActor.assumeIsolated(body)
        }
        CATransaction.commit()
    }

    private static var millisecondsSinceProcessStart: Double {
        guard let start = processStartDate else { return .nan }
        return Date().timeIntervalSince(start) * 1000
    }

    private static var preMainMilliseconds: Double {
        guard let start = processStartDate else { return .nan }
        return firstCodeExecutionDate.timeIntervalSince(start) * 1000
    }

    /// Captured the first time this type is touched, i.e. from `beginLaunch()`.
    private static let firstCodeExecutionDate = Date()

    /// Real process start, from the kernel, so pre-main time is accounted for.
    private static let processStartDate: Date? = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, ProcessInfo.processInfo.processIdentifier]
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return nil }
        let startTime = info.kp_proc.p_starttime
        return Date(timeIntervalSince1970: Double(startTime.tv_sec) + Double(startTime.tv_usec) / 1_000_000)
    }()
}
