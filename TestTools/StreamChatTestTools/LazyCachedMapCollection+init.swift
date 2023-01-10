//
//  LazyCachedMapCollection+init.swift
//  StreamChatTestTools
//
//  Created by Nuno Vieira on 10/01/2023.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension LazyCachedMapCollection {
    init<Collection: RandomAccessCollection, SourceElement>(
        source: Collection,
        map: @escaping (SourceElement) -> Element
    ) where Collection.Element == SourceElement, Collection.Index == Index {
        self.init(source: source, map: map, context: nil)
    }
}

public extension RandomAccessCollection where Index == Int {
    /// Lazily apply transformation to sequence
    func lazyCachedMap<T>(_ transformation: @escaping (Element) -> T) -> LazyCachedMapCollection<T> {
        .init(source: self, map: transformation, context: nil)
    }
}
