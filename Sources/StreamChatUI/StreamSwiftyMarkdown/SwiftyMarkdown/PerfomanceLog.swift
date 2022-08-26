//
//  PerfomanceLog.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation
import os.log

class PerformanceLog {
	var timer : TimeInterval = 0
	let enablePerfomanceLog : Bool
	let log : OSLog
	let identifier : String
	
	init( with environmentVariableName : String, identifier : String, log : OSLog  ) {
		self.log = log
		self.enablePerfomanceLog = (ProcessInfo.processInfo.environment[environmentVariableName] != nil)
		self.identifier = identifier
	}
	
	func start() {
		guard enablePerfomanceLog else { return }
		self.timer = Date().timeIntervalSinceReferenceDate
		os_log("--- TIMER %{public}@ began", log: self.log, type: .info, self.identifier)
	}
	
	func tag( with string : String) {
		guard enablePerfomanceLog else { return }
		if timer == 0 {
			self.start()
		}
		os_log("TIMER %{public}@: %f %@", log: self.log, type: .info, self.identifier, Date().timeIntervalSinceReferenceDate - self.timer, string)
	}
	
	func end() {
		guard enablePerfomanceLog else { return }
		self.timer = Date().timeIntervalSinceReferenceDate
		os_log("--- TIMER %{public}@ finished. Total time: %f", log: self.log, type: .info, self.identifier, Date().timeIntervalSinceReferenceDate - self.timer)
		self.timer = 0

	}
}
