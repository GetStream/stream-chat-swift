//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

//
//  SwiftyScanner.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = "SwiftyScanner"
    static let swiftyScanner = OSLog(subsystem: subsystem, category: "Swifty Scanner Scanner")
    static let swiftyScannerPerformance = OSLog(subsystem: subsystem, category: "Swifty Scanner Scanner Peformance")
}

enum RepeatingTagType {
    case open
    case either
    case close
    case neither
}

struct TagGroup {
    let groupID = UUID().uuidString
    var tagRanges: [ClosedRange<Int>]
    var tagType: RepeatingTagType = .open
    var count = 1
}

class SwiftyScanner {
    var elements: [Element]
    let rule: CharacterRule
    let metadata: [String: String]
    var pointer: Int = 0
	
    var spaceAndNewLine = CharacterSet.whitespacesAndNewlines
    var tagGroups: [TagGroup] = []
	
    var isMetadataOpen = false
	
    var enableLog = (ProcessInfo.processInfo.environment["SwiftyScannerScanner"] != nil)
	
    let currentPerfomanceLog = PerformanceLog(
        with: "SwiftyScannerScannerPerformanceLogging",
        identifier: "Scanner",
        log: OSLog.swiftyScannerPerformance
    )
    let log = PerformanceLog(with: "SwiftyScannerScanner", identifier: "Scanner", log: OSLog.swiftyScanner)
		
    enum Position {
        case forward(Int)
        case backward(Int)
    }
	
    init(withElements elements: [Element], rule: CharacterRule, metadata: [String: String]) {
        self.elements = elements
        self.rule = rule
        currentPerfomanceLog.start()
        self.metadata = metadata
    }
	
    func elementsBetweenCurrentPosition(and newPosition: Position) -> [Element]? {
        let newIdx: Int
        var isForward = true
        switch newPosition {
        case let .backward(positions):
            isForward = false
            newIdx = pointer - positions
            if newIdx < 0 {
                return nil
            }
        case let .forward(positions):
            newIdx = pointer + positions
            if newIdx >= elements.count {
                return nil
            }
        }
		
        let range: ClosedRange<Int> = (isForward) ? pointer...newIdx : newIdx...pointer
        return Array(elements[range])
    }
	
    func element(for position: Position) -> Element? {
        let newIdx: Int
        switch position {
        case let .backward(positions):
            newIdx = pointer - positions
            if newIdx < 0 {
                return nil
            }
        case let .forward(positions):
            newIdx = pointer + positions
            if newIdx >= elements.count {
                return nil
            }
        }
        return elements[newIdx]
    }
	
    func positionIsEqualTo(character: Character, direction: Position) -> Bool {
        guard let validElement = element(for: direction) else {
            return false
        }
        return validElement.character == character
    }
	
    func positionContains(characters: [Character], direction: Position) -> Bool {
        guard let validElement = element(for: direction) else {
            return false
        }
        return characters.contains(validElement.character)
    }
	
    func isEscaped() -> Bool {
        let isEscaped = positionContains(characters: rule.escapeCharacters, direction: .backward(1))
        if isEscaped {
            elements[pointer - 1].type = .escape
        }
        return isEscaped
    }
	
    func range(for tag: String?) -> ClosedRange<Int>? {
        guard let tag = tag else {
            return nil
        }
		
        guard let openChar = tag.first else {
            return nil
        }
		
        if pointer == elements.count {
            return nil
        }
		
        if elements[pointer].character != openChar {
            return nil
        }
		
        if isEscaped() {
            return nil
        }
		
        let range: ClosedRange<Int>
        if tag.count > 1 {
            guard let elements = elementsBetweenCurrentPosition(and: .forward(tag.count - 1)) else {
                return nil
            }
            // If it's already a tag, then it should be ignored
            if !elements.filter({ $0.type != .string }).isEmpty {
                return nil
            }
            if elements.map({ String($0.character) }).joined() != tag {
                return nil
            }
            let endIdx = (pointer + tag.count - 1)
            for i in pointer...endIdx {
                self.elements[i].type = .tag
            }
            range = pointer...endIdx
            pointer += tag.count
        } else {
            // If it's already a tag, then it should be ignored
            if elements[pointer].type != .string {
                return nil
            }
            elements[pointer].type = .tag
            range = pointer...pointer
            pointer += 1
        }
        return range
    }
	
    func resetTagGroup(withID id: String) {
        if let idx = tagGroups.firstIndex(where: { $0.groupID == id }) {
            for range in tagGroups[idx].tagRanges {
                resetTag(in: range)
            }
            tagGroups.remove(at: idx)
        }
        isMetadataOpen = false
    }
	
    func resetTag(in range: ClosedRange<Int>) {
        for idx in range {
            elements[idx].type = .string
        }
    }
	
    func resetLastTag(for range: inout [ClosedRange<Int>]) {
        guard let last = range.last else {
            return
        }
        for idx in last {
            elements[idx].type = .string
        }
    }
	
    func closeTag(_ tag: String, withGroupID id: String) {
        guard let tagIdx = tagGroups.firstIndex(where: { $0.groupID == id }) else {
            return
        }

        var metadataString = ""
        if isMetadataOpen {
            let metadataCloseRange = tagGroups[tagIdx].tagRanges.removeLast()
            let metadataOpenRange = tagGroups[tagIdx].tagRanges.removeLast()
			
            if metadataOpenRange.upperBound + 1 == (metadataCloseRange.lowerBound) {
                if enableLog {
                    os_log("Nothing between the tags", log: OSLog.swiftyScanner, type: .info, rule.description)
                }
            } else {
                for idx in (metadataOpenRange.upperBound)...(metadataCloseRange.lowerBound) {
                    elements[idx].type = .metadata
                    if rule.definesBoundary {
                        elements[idx].boundaryCount += 1
                    }
                }
				
                let key = elements[metadataOpenRange.upperBound + 1..<metadataCloseRange.lowerBound].map { String($0.character) }
                    .joined()
                if rule.metadataLookup {
                    metadataString = metadata[key] ?? ""
                } else {
                    metadataString = key
                }
            }
        }
		
        let closeRange = tagGroups[tagIdx].tagRanges.removeLast()
        let openRange = tagGroups[tagIdx].tagRanges.removeLast()

        if rule.balancedTags && closeRange.count != openRange.count {
            tagGroups[tagIdx].tagRanges.append(openRange)
            tagGroups[tagIdx].tagRanges.append(closeRange)
            return
        }

        var shouldRemove = true
        var styles: [CharacterStyling] = []
        if openRange.upperBound + 1 == (closeRange.lowerBound) {
            if enableLog {
                os_log("Nothing between the tags", log: OSLog.swiftyScanner, type: .info, rule.description)
            }
        } else {
            var remainingTags = min(openRange.upperBound - openRange.lowerBound, closeRange.upperBound - closeRange.lowerBound) + 1
            while remainingTags > 0 {
                if remainingTags >= rule.maxTags {
                    remainingTags -= rule.maxTags
                    if let style = rule.styles[rule.maxTags] {
                        if !styles.contains(where: { $0.isEqualTo(style) }) {
                            styles.append(style)
                        }
                    }
                }
                if let style = rule.styles[remainingTags] {
                    remainingTags -= remainingTags
                    if !styles.contains(where: { $0.isEqualTo(style) }) {
                        styles.append(style)
                    }
                }
            }
			
            for idx in (openRange.upperBound)...(closeRange.lowerBound) {
                elements[idx].styles.append(contentsOf: styles)
                elements[idx].metadata.append(metadataString)
                if rule.definesBoundary {
                    elements[idx].boundaryCount += 1
                }
                if rule.shouldCancelRemainingRules {
                    elements[idx].boundaryCount = 1000
                }
            }
			
            if rule.isRepeatingTag {
                let difference = (openRange.upperBound - openRange.lowerBound) - (closeRange.upperBound - closeRange.lowerBound)
                switch difference {
                case 1...:
                    shouldRemove = false
                    tagGroups[tagIdx].count = difference
                    tagGroups[tagIdx].tagRanges.append(openRange.upperBound - (abs(difference) - 1)...openRange.upperBound)
                case ...(-1):
                    for idx in closeRange.upperBound - (abs(difference) - 1)...closeRange.upperBound {
                        elements[idx].type = .string
                    }
                default:
                    break
                }
            }
        }
        if shouldRemove {
            tagGroups.removeAll(where: { $0.groupID == id })
        }
        isMetadataOpen = false
    }
	
    func emptyRanges(_ ranges: inout [ClosedRange<Int>]) {
        while !ranges.isEmpty {
            resetLastTag(for: &ranges)
            ranges.removeLast()
        }
    }
	
    func scanNonRepeatingTags() {
        var groupID = ""
        let closeTag = rule.tag(for: .close)?.tag
        let metadataOpen = rule.tag(for: .metadataOpen)?.tag
        let metadataClose = rule.tag(for: .metadataClose)?.tag
		
        while pointer < elements.count {
            if enableLog {
                os_log("CHARACTER: %@", log: OSLog.swiftyScanner, type: .info, String(elements[pointer].character))
            }
			
            if let range = self.range(for: metadataClose) {
                if isMetadataOpen {
                    guard let groupIdx = tagGroups.firstIndex(where: { $0.groupID == groupID }) else {
                        pointer += 1
                        continue
                    }
					
                    guard !tagGroups.isEmpty else {
                        resetTagGroup(withID: groupID)
                        continue
                    }
				
                    guard isMetadataOpen else {
                        resetTagGroup(withID: groupID)
                        continue
                    }
                    if enableLog {
                        os_log("Closing metadata tag found. Closing tag with ID %@", log: OSLog.swiftyScanner, type: .info, groupID)
                    }
                    tagGroups[groupIdx].tagRanges.append(range)
                    self.closeTag(closeTag!, withGroupID: groupID)
                    isMetadataOpen = false
                    continue
                } else {
                    resetTag(in: range)
                    pointer -= metadataClose!.count
                }
            }
			
            if let openRange = range(for: rule.primaryTag.tag) {
                if isMetadataOpen {
                    resetTagGroup(withID: groupID)
                }
				
                let tagGroup = TagGroup(tagRanges: [openRange])
                groupID = tagGroup.groupID
                if enableLog {
                    os_log("New tag found. Starting new Group with ID %@", log: OSLog.swiftyScanner, type: .info, groupID)
                }
                if rule.isRepeatingTag {}
				
                tagGroups.append(tagGroup)
                continue
            }
	
            if let range = self.range(for: closeTag) {
                guard !tagGroups.isEmpty else {
                    if enableLog {
                        os_log("No tags exist, resetting this close tag", log: OSLog.swiftyScanner, type: .info)
                    }
                    resetTag(in: range)
                    continue
                }
                tagGroups[tagGroups.count - 1].tagRanges.append(range)
                groupID = tagGroups[tagGroups.count - 1].groupID
                if enableLog {
                    os_log("New close tag found. Appending to group with ID %@", log: OSLog.swiftyScanner, type: .info, groupID)
                }
                guard metadataOpen != nil else {
                    if enableLog {
                        os_log(
                            "No metadata tags exist, closing valid tag with ID %@",
                            log: OSLog.swiftyScanner,
                            type: .info,
                            groupID
                        )
                    }
                    self.closeTag(closeTag!, withGroupID: groupID)
                    continue
                }
				
                guard pointer != elements.count else {
                    continue
                }
				
                guard let range = self.range(for: metadataOpen) else {
                    if enableLog {
                        os_log("No metadata tag found, resetting group with ID %@", log: OSLog.swiftyScanner, type: .info, groupID)
                    }
                    resetTagGroup(withID: groupID)
                    continue
                }
                tagGroups[tagGroups.count - 1].tagRanges.append(range)
                isMetadataOpen = true
                continue
            }
			
            if let range = self.range(for: metadataOpen) {
                if enableLog {
                    os_log("Multiple metadata tags found!", log: OSLog.swiftyScanner, type: .info, groupID)
                }
                resetTag(in: range)
                resetTagGroup(withID: groupID)
                isMetadataOpen = false
                continue
            }
            pointer += 1
        }
    }
	
    func scanRepeatingTags() {
        var groupID = ""
        let escapeCharacters = "" // self.rule.escapeCharacters.map( { String( $0 ) }).joined()
        let unionSet = spaceAndNewLine.union(CharacterSet(charactersIn: escapeCharacters))
        while pointer < elements.count {
            if enableLog {
                os_log("CHARACTER: %@", log: OSLog.swiftyScanner, type: .info, String(elements[pointer].character))
            }
			
            if var openRange = range(for: rule.primaryTag.tag) {
                if elements[openRange].first?.boundaryCount == 1000 {
                    resetTag(in: openRange)
                    continue
                }
				
                var count = 1
                var tagType: RepeatingTagType = .open
                if let prevElement = element(for: .backward(rule.primaryTag.tag.count + 1)) {
                    if !unionSet.containsUnicodeScalars(of: prevElement.character) {
                        tagType = .either
                    }
                } else {
                    tagType = .open
                }
				
                while let nextRange = range(for: rule.primaryTag.tag) {
                    count += 1
                    openRange = openRange.lowerBound...nextRange.upperBound
                }
				
                if rule.minTags > 1 {
                    if (openRange.upperBound - openRange.lowerBound) + 1 < rule.minTags {
                        resetTag(in: openRange)
                        os_log("Tag does not meet minimum length", log: .swiftyScanner, type: .info)
                        continue
                    }
                }
				
                var validTagGroup = true
                if let nextElement = element(for: .forward(0)) {
                    if unionSet.containsUnicodeScalars(of: nextElement.character) {
                        if tagType == .either {
                            tagType = .close
                        } else {
                            validTagGroup = tagType != .open
                        }
                    }
                } else {
                    if tagType == .either {
                        tagType = .close
                    } else {
                        validTagGroup = tagType != .open
                    }
                }
				
                if !validTagGroup {
                    if enableLog {
                        os_log("Tag has whitespace on both sides", log: .swiftyScanner, type: .info)
                    }
                    resetTag(in: openRange)
                    continue
                }
				
                if let idx = tagGroups.firstIndex(where: { $0.groupID == groupID }) {
                    if tagType == .either {
                        if tagGroups[idx].count == count {
                            tagGroups[idx].tagRanges.append(openRange)
                            closeTag(rule.primaryTag.tag, withGroupID: groupID)
							
                            if let last = tagGroups.last {
                                groupID = last.groupID
                            }
							
                            continue
                        }
                    } else {
                        if let prevRange = tagGroups[idx].tagRanges.first {
                            if elements[prevRange].first?.boundaryCount == elements[openRange].first?.boundaryCount {
                                tagGroups[idx].tagRanges.append(openRange)
                                closeTag(rule.primaryTag.tag, withGroupID: groupID)
                            }
                        }
                        continue
                    }
                }
                var tagGroup = TagGroup(tagRanges: [openRange])
                groupID = tagGroup.groupID
                tagGroup.tagType = tagType
                tagGroup.count = count
				
                if enableLog {
                    os_log(
                        "New tag found with characters %@. Starting new Group with ID %@",
                        log: OSLog.swiftyScanner,
                        type: .info,
                        elements[openRange].map { String($0.character) }.joined(),
                        groupID
                    )
                }
				
                tagGroups.append(tagGroup)
                continue
            }
	
            pointer += 1
        }
    }
	
    func scan() -> [Element] {
        guard elements.filter({ $0.type == .string }).map({ String($0.character) }).joined().contains(rule.primaryTag.tag) else {
            return elements
        }
		
        currentPerfomanceLog.tag(with: "Beginning \(rule.primaryTag.tag)")
		
        if enableLog {
            os_log("RULE: %@", log: OSLog.swiftyScanner, type: .info, rule.description)
        }
		
        if rule.isRepeatingTag {
            scanRepeatingTags()
        } else {
            scanNonRepeatingTags()
        }
		
        for tagGroup in tagGroups {
            resetTagGroup(withID: tagGroup.groupID)
        }
		
        if enableLog {
            for element in elements {
                print(element)
            }
        }
        return elements
    }
}
