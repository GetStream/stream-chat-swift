//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import os.log

class PerformanceLog {
    var timer: TimeInterval = 0
    let enablePerfomanceLog: Bool
    let log: OSLog
    let identifier: String
	
    init(with environmentVariableName: String, identifier: String, log: OSLog) {
        self.log = log
        enablePerfomanceLog = (ProcessInfo.processInfo.environment[environmentVariableName] != nil)
        self.identifier = identifier
    }
	
    func start() {
        guard enablePerfomanceLog else { return }
        timer = Date().timeIntervalSinceReferenceDate
        os_log("--- TIMER %{public}@ began", log: log, type: .info, identifier)
    }
	
    func tag(with string: String) {
        guard enablePerfomanceLog else { return }
        if timer == 0 {
            start()
        }
        os_log("TIMER %{public}@: %f %@", log: log, type: .info, identifier, Date().timeIntervalSinceReferenceDate - timer, string)
    }
	
    func end() {
        guard enablePerfomanceLog else { return }
        timer = Date().timeIntervalSinceReferenceDate
        os_log(
            "--- TIMER %{public}@ finished. Total time: %f",
            log: log,
            type: .info,
            identifier,
            Date().timeIntervalSinceReferenceDate - timer
        )
        timer = 0
    }
}
