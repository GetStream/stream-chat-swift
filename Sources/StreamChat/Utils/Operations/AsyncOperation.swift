//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        executedRetries < maxRetries && !isCancelled && !isFinished
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
        execute()
    }

    private func execute() {
        executionBlock(self) { [weak self] in
            self?.handleResult($0)
        }
    }

    private func handleResult(_ output: Output) {
        let shouldRetry = output == .retry && canRetry
        guard shouldRetry else {
            isExecuting = false
            isFinished = true
            return
        }

        executedRetries += 1
        execute()
    }

    func resetRetries() {
        executedRetries = 0
    }
}

class BaseOperation: Operation {
    private var _finished = false
    private var _executing = false
    private let stateQueue = DispatchQueue(label: "io.getstream.base-operation", attributes: .concurrent)

    override var isExecuting: Bool {
        get {
            stateQueue.sync {
                _executing
            }
        }
        set {
            willChangeValue(for: \.isExecuting)
            stateQueue.async(flags: .barrier) {
                self._executing = newValue
            }
            didChangeValue(for: \.isExecuting)
        }
    }

    override var isFinished: Bool {
        get {
            stateQueue.sync {
                _finished
            }
        }
        set {
            willChangeValue(for: \.isFinished)
            stateQueue.async(flags: .barrier) {
                self._finished = newValue
            }
            didChangeValue(for: \.isFinished)
        }
    }
}
