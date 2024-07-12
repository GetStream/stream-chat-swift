//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A component responsible for the logic of computing delays for failed actions that needs to be retried.
protocol RetryStrategy {
    /// Resets the retry mechanism.
    func reset()

    /// Returns the delay for the next retry.
    /// Throws error in case it should not retry.
    func delay() throws -> TimeInterval
}

/// The default implementation of `RetryStrategy` with exponentially growing delays.
///
/// Consecutive calls after the same # of failures may return different delays. This randomization is done to
/// make the retry intervals slightly different for different callers to avoid putting the backend down by
/// making all the retries at the same time.
class ExponentialBackoffRetryStrategy: RetryStrategy {
    @Atomic private var consecutiveFailuresCount = 0

    let maximumReconnectionDelay: TimeInterval
    let maximumNumberOfRetries: Int

    init(
        maximumReconnectionDelay: TimeInterval,
        maximumNumberOfRetries: Int
    ) {
        self.maximumReconnectionDelay = maximumReconnectionDelay
        self.maximumNumberOfRetries = maximumNumberOfRetries
    }

    func reset() {
        _consecutiveFailuresCount.mutate { $0 = 0 }
    }

    func delay() throws -> TimeInterval {
        if consecutiveFailuresCount >= maximumNumberOfRetries {
            throw ClientError.RetryTimeout("Connection Retry has timed out.")
        }

        var delay: TimeInterval = 0

        _consecutiveFailuresCount.mutate {
            let maxDelay: TimeInterval = min(0.5 + Double($0 * 2), maximumReconnectionDelay)
            let minDelay: TimeInterval = min(max(0.25, (Double($0) - 1) * 2), maximumReconnectionDelay)

            delay = TimeInterval.random(in: minDelay...maxDelay)
        }

        incrementConsecutiveFailures()

        return delay
    }

    private func incrementConsecutiveFailures() {
        _consecutiveFailuresCount.mutate { $0 += 1 }
    }
}

extension ClientError {
    final class RetryTimeout: ClientError {}
}
