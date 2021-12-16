//
//  Array+SafeSubscript.swift
//  StreamChat
//
//  Created by Pol Quintana on 14/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    /// Triggers indexNotFoundAssertion if the index is not present in the collection.
    /// Mostly used in places where returning optional would be a breaking change
    func assertIndexIsPresent(_ index: Index,
                              functionName: StaticString = #function,
                              fileName: StaticString = #file,
                              lineNumber: UInt = #line) {
        guard !indices.contains(index) else { return }
        indexNotFoundAssertion(functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
}

func indexNotFoundAssertion(functionName: StaticString = #function,
                            fileName: StaticString = #file,
                            lineNumber: UInt = #line) {
    log.assertionFailure("Accessing an index that is not present in the data source",
                         functionName: functionName,
                         fileName: fileName,
                         lineNumber: lineNumber)
}
