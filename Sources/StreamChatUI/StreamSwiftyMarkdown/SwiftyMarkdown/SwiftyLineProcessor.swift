//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = "SwiftyLineProcessor"
    static let swiftyLineProcessorPerformance = OSLog(subsystem: subsystem, category: "Swifty Line Processor Performance")
}

protocol LineStyling {
    var shouldTokeniseLine: Bool { get }
    func styleIfFoundStyleAffectsPreviousLine() -> LineStyling?
}

struct SwiftyLine: CustomStringConvertible {
    let line: String
    let lineStyle: LineStyling
    var description: String {
        line
    }
}

extension SwiftyLine: Equatable {
    static func == (_ lhs: SwiftyLine, _ rhs: SwiftyLine) -> Bool {
        lhs.line == rhs.line
    }
}

enum Remove {
    case leading
    case trailing
    case both
    case entireLine
    case none
}

enum ChangeApplication {
    case current
    case previous
    case untilClose
}

struct FrontMatterRule {
    let openTag: String
    let closeTag: String
    let keyValueSeparator: Character
}

struct LineRule {
    let token: String
    let removeFrom: Remove
    let type: LineStyling
    let shouldTrim: Bool
    let changeAppliesTo: ChangeApplication
    
    init(
        token: String,
        type: LineStyling,
        removeFrom: Remove = .leading,
        shouldTrim: Bool = true,
        changeAppliesTo: ChangeApplication = .current
    ) {
        self.token = token
        self.type = type
        self.removeFrom = removeFrom
        self.shouldTrim = shouldTrim
        self.changeAppliesTo = changeAppliesTo
    }
}

class SwiftyLineProcessor {
    var processEmptyStrings: LineStyling?
    var frontMatterAttributes: [String: String] = [:]
	
    var closeToken: String?
    let defaultType: LineStyling
    
    let lineRules: [LineRule]
    let frontMatterRules: [FrontMatterRule]
	
    let perfomanceLog = PerformanceLog(
        with: "SwiftyLineProcessorPerformanceLogging",
        identifier: "Line Processor",
        log: OSLog.swiftyLineProcessorPerformance
    )
	    
    init(rules: [LineRule], defaultRule: LineStyling, frontMatterRules: [FrontMatterRule] = []) {
        lineRules = rules
        defaultType = defaultRule
        self.frontMatterRules = frontMatterRules
    }
    
    func findLeadingLineElement(_ element: LineRule, in string: String) -> String {
        var output = string
        if let range = output.index(output.startIndex, offsetBy: element.token.count, limitedBy: output.endIndex),
           output[output.startIndex..<range] == element.token {
            output.removeSubrange(output.startIndex..<range)
            return output
        }
        return output
    }
    
    func findTrailingLineElement(_ element: LineRule, in string: String) -> String {
        var output = string
        let token = element.token.trimmingCharacters(in: .whitespaces)
        if let range = output.index(output.endIndex, offsetBy: -(token.count), limitedBy: output.startIndex),
           output[range..<output.endIndex] == token {
            output.removeSubrange(range..<output.endIndex)
            return output
        }
        return output
    }
    
    func processLineLevelAttributes(_ text: String) -> SwiftyLine? {
        if text.isEmpty, let style = processEmptyStrings {
            return SwiftyLine(line: "", lineStyle: style)
        }
        let previousLines = lineRules.filter { $0.changeAppliesTo == .previous }

        for element in lineRules {
            guard !element.token.isEmpty else {
                continue
            }
            var output: String = (element.shouldTrim) ? text.trimmingCharacters(in: .whitespaces) : text
            let unprocessed = output
			
            if let hasToken = closeToken, unprocessed != hasToken {
                return nil
            }
            
            if !text.contains(element.token) {
                continue
            }
			
            switch element.removeFrom {
            case .leading:
                output = findLeadingLineElement(element, in: output)
            case .trailing:
                output = findTrailingLineElement(element, in: output)
            case .both:
                output = findLeadingLineElement(element, in: output)
                output = findTrailingLineElement(element, in: output)
            case .entireLine:
                let maybeOutput = output.replacingOccurrences(of: element.token, with: "")
                output = (maybeOutput.isEmpty) ? maybeOutput : output
            default:
                break
            }
            // Only if the output has changed in some way
            guard unprocessed != output else {
                continue
            }
            if element.changeAppliesTo == .untilClose {
                closeToken = (closeToken == nil) ? element.token : nil
                return nil
            }

            output = (element.shouldTrim) ? output.trimmingCharacters(in: .whitespaces) : output
            return SwiftyLine(line: output, lineStyle: element.type)
        }
        
        for element in previousLines {
            let output = (element.shouldTrim) ? text.trimmingCharacters(in: .whitespaces) : text
            let charSet = CharacterSet(charactersIn: element.token)
            if output.unicodeScalars.allSatisfy({ charSet.contains($0) }) {
                return SwiftyLine(line: "", lineStyle: element.type)
            }
        }
		
        return SwiftyLine(line: text.trimmingCharacters(in: .whitespaces), lineStyle: defaultType)
    }
	
    func processFrontMatter(_ strings: [String]) -> [String] {
        guard let firstString = strings.first?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return strings
        }
        var rulesToApply: FrontMatterRule?
        for matter in frontMatterRules {
            if firstString == matter.openTag {
                rulesToApply = matter
                break
            }
        }
        guard let existentRules = rulesToApply else {
            return strings
        }
        var outputString = strings
        // Remove the first line, which is the front matter opening tag
        _ = outputString.removeFirst()
        var closeFound = false
        while !closeFound {
            let nextString = outputString.removeFirst()
            if nextString == existentRules.closeTag {
                closeFound = true
                continue
            }
            var keyValue = nextString.components(separatedBy: "\(existentRules.keyValueSeparator)")
            if keyValue.count < 2 {
                continue
            }
            let key = keyValue.removeFirst()
            let value = keyValue.joined()
            frontMatterAttributes[key] = value
        }
        while outputString.first?.isEmpty ?? false {
            outputString.removeFirst()
        }
        return outputString
    }
    
    func process(_ string: String) -> [SwiftyLine] {
        var foundAttributes: [SwiftyLine] = []
		
        perfomanceLog.start()
		
        var lines = string.components(separatedBy: CharacterSet.newlines)
        lines = processFrontMatter(lines)
		
        perfomanceLog.tag(with: "(Front matter completed)")
		
        for heading in lines {
            if processEmptyStrings == nil && heading.isEmpty {
                continue
            }
			            
            guard let input = processLineLevelAttributes(String(heading)) else {
                continue
            }
			
            if let existentPrevious = input.lineStyle.styleIfFoundStyleAffectsPreviousLine(), !foundAttributes.isEmpty {
                if let idx = foundAttributes.firstIndex(of: foundAttributes.last!) {
                    let updatedPrevious = foundAttributes.last!
                    foundAttributes[idx] = SwiftyLine(line: updatedPrevious.line, lineStyle: existentPrevious)
                }
                continue
            }
            foundAttributes.append(input)
			
            perfomanceLog.tag(with: "(line completed: \(heading)")
        }
        return foundAttributes
    }
}
