//
//  Array+Extensions.swift
//  StreamChat
//
//  Created by Matheus Cardoso on 4/1/20.
//

import Foundation

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
