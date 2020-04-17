//
//  Array+Extensions.swift
//  StreamChat
//
//  Created by Matheus Cardoso on 4/1/20.
//

import Foundation

extension Array {
    
    /// Safely accesses the element at the specified position.
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }
        
        return self[index]
    }
    
    /// Split the array in chunks with athe given size.
    /// - Parameter size: a chunk size.
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}
