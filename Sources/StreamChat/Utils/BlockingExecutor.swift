//
// Created by kojiba on 10.09.2021.
// Copyright (c) 2021 Stream.io Inc. All rights reserved.
//

import Foundation

class BlockingExecutor {
    typealias Completion = (Error?) -> Void
    typealias ExecutorClosure = (_: @escaping Completion) -> Void

    @Atomic private var executionIsInProgress: Bool = false

    private let executorTitle: String

    init(executorTitle: String) {
        self.executorTitle = executorTitle
    }

    /// Execute given operations in a serial queue
    /// - Parameters:
    ///   - executor: Closure which represents operation to be executed,
    ///               in the end of operation executor should call it's completion argument.
    ///   - completion: Closure which will be called after executor completion.
    func executeBlocking(executor: @escaping ExecutorClosure, completion: @escaping Completion) {
        if _executionIsInProgress.compareAndSwap(old: false, new: true) {
            executor { [weak self] error in
                self?.executionIsInProgress = false
                completion(error)
            }
        } else {
            completion(ClientError.ExecutingAlreadyInProgress(executorTitle: executorTitle))
        }
    }
}

extension ClientError {
    class ExecutingAlreadyInProgress: ClientError {
        let executorTitle: String

        init(executorTitle: String) {
            self.executorTitle = executorTitle
            super.init(executorTitle)
        }

        override public var localizedDescription: String {
            self.executorTitle + ":" + "Operation is already in progress, please call this function after previous operation finished"
        }
    }
}
