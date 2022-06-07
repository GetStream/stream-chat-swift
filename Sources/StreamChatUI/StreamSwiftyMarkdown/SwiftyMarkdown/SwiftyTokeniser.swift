//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

//
//  SwiftyTokeniser.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 16/12/2019.
//  Copyright © 2019 Voyage Travel Apps. All rights reserved.
//
import Foundation
import os.log

extension OSLog {
    private static var subsystem = "SwiftyTokeniser"
    static let tokenising = OSLog(subsystem: subsystem, category: "Tokenising")
    static let styling = OSLog(subsystem: subsystem, category: "Styling")
    static let performance = OSLog(subsystem: subsystem, category: "Peformance")
}

class SwiftyTokeniser {
    let rules: [CharacterRule]
    var replacements: [String: [Token]] = [:]
	
    var enableLog = (ProcessInfo.processInfo.environment["SwiftyTokeniserLogging"] != nil)
    let totalPerfomanceLog = PerformanceLog(
        with: "SwiftyTokeniserPerformanceLogging",
        identifier: "Tokeniser Total Run Time",
        log: OSLog.performance
    )
    let currentPerfomanceLog = PerformanceLog(
        with: "SwiftyTokeniserPerformanceLogging",
        identifier: "Tokeniser Current",
        log: OSLog.performance
    )
		
    var metadataLookup: [String: String] = [:]
	
    let newlines = CharacterSet.newlines
    let spaces = CharacterSet.whitespaces

    init(with rules: [CharacterRule]) {
        self.rules = rules
		
        totalPerfomanceLog.start()
    }
	
    deinit {
        self.totalPerfomanceLog.end()
    }
	
    /// This goes through every CharacterRule in order and applies it to the input string, tokenising the string
    /// if there are any matches.
    ///
    /// The for loop in the while loop (yeah, I know) is there to separate strings from within tags to
    /// those outside them.
    ///
    /// e.g. "A string with a \[link\]\(url\) tag" would have the "link" text tokenised separately.
    ///
    /// This is to prevent situations like **\[link**\](url) from returing a bold string.
    ///
    /// - Parameter inputString: A string to have the CharacterRules in `self.rules` applied to
    func process(_ inputString: String) -> [Token] {
        let currentTokens = [Token(type: .string, inputString: inputString)]
        guard !rules.isEmpty else {
            return currentTokens
        }
        var mutableRules = rules
		
        if inputString.isEmpty {
            return [Token(type: .string, inputString: "", characterStyles: [])]
        }
		
        currentPerfomanceLog.start()
	
        var elementArray: [Element] = []
        for char in inputString {
            if newlines.containsUnicodeScalars(of: char) {
                let element = Element(character: char, type: .newline)
                elementArray.append(element)
                continue
            }
            if spaces.containsUnicodeScalars(of: char) {
                let element = Element(character: char, type: .space)
                elementArray.append(element)
                continue
            }
            let element = Element(character: char, type: .string)
            elementArray.append(element)
        }
		
        while !mutableRules.isEmpty {
            let nextRule = mutableRules.removeFirst()
            if enableLog {
                os_log("------------------------------", log: .tokenising, type: .info)
                os_log("RULE: %@", log: OSLog.tokenising, type: .info, nextRule.description)
            }
            currentPerfomanceLog.tag(with: "(start rule %@)")
			
            let scanner = SwiftyScanner(withElements: elementArray, rule: nextRule, metadata: metadataLookup)
            elementArray = scanner.scan()
        }
		
        var output: [Token] = []
        var lastElement = elementArray.first!
		
        func empty(_ string: inout String, into tokens: inout [Token]) {
            guard !string.isEmpty else {
                return
            }
            var token = Token(type: .string, inputString: string)
            token.metadataStrings.append(contentsOf: lastElement.metadata)
            token.characterStyles = lastElement.styles
            string.removeAll()
            tokens.append(token)
        }
		
        var accumulatedString = ""
        for element in elementArray {
            guard element.type != .escape else {
                continue
            }
			
            guard element.type == .string || element.type == .space || element.type == .newline else {
                empty(&accumulatedString, into: &output)
                continue
            }
            if lastElement.styles as? [CharacterStyle] != element.styles as? [CharacterStyle] {
                empty(&accumulatedString, into: &output)
            }
            accumulatedString.append(element.character)
            lastElement = element
        }
        empty(&accumulatedString, into: &output)
		
        currentPerfomanceLog.tag(with: "(finished all rules)")
		
        if enableLog {
            os_log("=====RULE PROCESSING COMPLETE=====", log: .tokenising, type: .info)
            os_log("==================================", log: .tokenising, type: .info)
        }
        return output
    }
}

extension String {
    func repeating(_ max: Int) -> String {
        var output = self
        for _ in 1..<max {
            output += self
        }
        return output
    }
}
