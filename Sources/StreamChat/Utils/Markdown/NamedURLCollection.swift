/**
 *  Ink
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Foundation

internal struct NamedURLCollection {
    private let urlsByName: [String: Substring]

    init(urlsByName: [String: Substring]) {
        self.urlsByName = urlsByName
    }

    func url(named name: Substring) -> Substring? {
        urlsByName[name.lowercased()]
    }
}
