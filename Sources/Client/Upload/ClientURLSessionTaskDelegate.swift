//
//  ClientURLSessionTaskDelegate.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 30/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

final class ClientURLSessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    
    let uploadProgress = PublishSubject<(task: URLSessionTask, progress: Float, error: Error?)>()
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        let progress = totalBytesExpectedToSend > 0 ? Float(Double(totalBytesSent) / Double(totalBytesExpectedToSend)) : 0
        
        if totalBytesExpectedToSend > 10240 {
            let message = "⏫ [\(task.taskIdentifier)] \(totalBytesSent)/\(totalBytesExpectedToSend), \((progress * 100).rounded())%"
            Client.shared.logger?.log(message, level: .info)
        }
        
        uploadProgress.onNext((task, progress, nil))
    }
}
