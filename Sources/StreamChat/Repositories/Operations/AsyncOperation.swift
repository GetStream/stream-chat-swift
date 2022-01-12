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
    private let executionBlock: (_ completion: @escaping (_ output: Output) -> Void) -> Void
    private var executedRetries = 0

    init(retries: Int = 0, executionBlock: @escaping (_ completion: @escaping (_ output: Output) -> Void) -> Void) {
        maxRetries = retries
        self.executionBlock = executionBlock
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true
        executionBlock(handleResult)
    }

    private func handleResult(_ output: Output) {
        guard output == .continue || executedRetries + 1 < maxRetries else {
            executedRetries += 1
            executionBlock(handleResult)
            return
        }
        isExecuting = false
        isFinished = true
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
