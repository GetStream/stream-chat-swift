//
//  ClientURLSessionTaskDelegate.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

final class ClientURLSessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    
    private var progressHandlers = [Int: Client.Progress]()
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 51200 else {
            return
        }
        
        let progress = totalBytesExpectedToSend > 0 ? Float(Double(totalBytesSent) / Double(totalBytesExpectedToSend)) : 0
        
        if Client.shared.logOptions.contains(.requestsInfo) {
            let percent = (progress * 1000).rounded() / 10
            ClientLogger.log("⏫", "[\(task.taskIdentifier)] \(totalBytesSent)/\(totalBytesExpectedToSend), \(percent)%")
        }
        
        DispatchQueue.main.async {
            self.updateHandler(id: task.taskIdentifier, progress: progress)
        }
    }
    
    func addProgessHandler(id: Int, _ progress: @escaping Client.Progress) {
        DispatchQueue.main.async {
            self.progressHandlers[id] = progress
        }
    }
    
    private func updateHandler(id: Int, progress: Float) {
        guard let progressHandler = progressHandlers[id] else {
            return
        }
        
        progressHandler(progress)
        
        if progress > 0.99 {
            progressHandlers.removeValue(forKey: id)
        }
    }
}
