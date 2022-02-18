//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class AsyncOperation: BaseOperation {
    enum Output {
        case retry
        case `continue`
    }

    private let maxRetries: Int
    private(set) var executionBlock: (AsyncOperation, @escaping (_ output: Output) -> Void) -> Void
    private var executedRetries = 0

    var canRetry: Bool {
        executedRetries < maxRetries && !isCancelled
    }

    init(maxRetries: Int = 0, executionBlock: @escaping (AsyncOperation, @escaping (_ output: Output) -> Void) -> Void) {
        self.maxRetries = maxRetries
        self.executionBlock = executionBlock
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true
        executionBlock(self, handleResult)
    }

    private func handleResult(_ output: Output) {
        if output == .retry && canRetry {
            executedRetries += 1
            executionBlock(self, handleResult)
        } else {
            isExecuting = false
            isFinished = true
        }
    }

    func resetRetries() {
        executedRetries = 0
    }
}

class BaseOperation: Operation {
    private var _finished = false
    private var _executing = false

    override var isExecuting: Bool {
        get {
            _executing
        }
        set {
            willChangeValue(for: \.isExecuting)
            _executing = newValue
            didChangeValue(for: \.isExecuting)
        }
    }

    override var isFinished: Bool {
        get {
            _finished
        }
        set {
            willChangeValue(for: \.isFinished)
            _finished = newValue
            didChangeValue(for: \.isFinished)
        }
    }
}
