//
//  Token.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 04/02/2020.
//

import Foundation

// Tag definition
protocol CharacterStyling {
	func isEqualTo( _ other : CharacterStyling ) -> Bool
}

// Token definition
enum TokenType {
	case repeatingTag
	case openTag
	case intermediateTag
	case closeTag
	case string
	case escape
	case replacement
}

struct Token {
	let id = UUID().uuidString
	let type : TokenType
	let inputString : String
	var metadataStrings : [String] = []
	var group : Int = 0
	var characterStyles : [CharacterStyling] = []
	var count : Int = 0
	var shouldSkip : Bool = false
	var tokenIndex : Int = -1
	var isProcessed : Bool = false
	var isMetadata : Bool = false
	var children : [Token] = []
	
	var outputString : String {
		get {
			switch self.type {
			case .repeatingTag:
				if count <= 0 {
					return ""
				} else {
					let range = inputString.startIndex..<inputString.index(inputString.startIndex, offsetBy: self.count)
					return String(inputString[range])
				}
			case .openTag, .closeTag, .intermediateTag:
				return (self.isProcessed || self.isMetadata) ? "" : inputString
			case .escape, .string:
				return (self.isProcessed || self.isMetadata) ? "" : inputString
			case .replacement:
				return self.inputString
			}
		}
	}
	init( type : TokenType, inputString : String, characterStyles : [CharacterStyling] = []) {
		self.type = type
		self.inputString = inputString
		self.characterStyles = characterStyles
		if type == .repeatingTag {
			self.count = inputString.count
		}
	}
	
	func newToken( fromSubstring string: String,  isReplacement : Bool) -> Token {
		var newToken = Token(type: (isReplacement) ? .replacement : .string , inputString: string, characterStyles: self.characterStyles)
		newToken.metadataStrings = self.metadataStrings
		newToken.isMetadata = self.isMetadata
		newToken.isProcessed = self.isProcessed
		return newToken
	}
}

extension Sequence where Iterator.Element == Token {
	var oslogDisplay: String {
		return "[\"\(self.map( {  ($0.outputString.isEmpty) ? "\($0.type): \($0.inputString)" : $0.outputString }).joined(separator: "\", \""))\"]"
	}
}
