/**
 *  Ink
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Foundation

internal struct URLDeclaration: Readable {
    var name: String
    var url: Substring

    static func read(using reader: inout Reader) throws -> Self {
        try reader.read("[")
        let name = try reader.read(until: "]")
        try reader.read(":")
        try reader.readWhitespaces()
        let url = reader.readUntilEndOfLine()

        return URLDeclaration(name: name.lowercased(), url: url)
    }
}
