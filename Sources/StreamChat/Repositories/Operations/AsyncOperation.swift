//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class AsyncOperation: BaseOperation {
    private let executionBlock: (_ completion: @escaping () -> Void) -> Void

    init(executionBlock: @escaping (_ completion: @escaping () -> Void) -> Void) {
        self.executionBlock = executionBlock
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true

        executionBlock {
            self.isExecuting = false
            self.isFinished = true
        }
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
