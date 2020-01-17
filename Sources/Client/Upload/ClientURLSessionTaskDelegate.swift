//
//  ClientURLSessionTaskDelegate.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

final class ClientURLSessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    
    var progressHandlers = [Int: Client.Progress]()
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        guard let progressHandler = progressHandlers[task.taskIdentifier] else {
            return
        }
        
        let progress = totalBytesExpectedToSend > 0 ? Float(Double(totalBytesSent) / Double(totalBytesExpectedToSend)) : 0
        
        if let logger = Client.shared.logger, totalBytesExpectedToSend > 10240 {
            logger.log("⏫ [\(task.taskIdentifier)] \(totalBytesSent)/\(totalBytesExpectedToSend), \((progress * 100).rounded())%",
                       level: .info)
        }
        
        progressHandler(progress)
        
        if progress >= 0.99 {
            progressHandlers.removeValue(forKey: task.taskIdentifier)
        }
    }
}
