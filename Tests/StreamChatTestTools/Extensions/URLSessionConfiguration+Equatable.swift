//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public extension URLSessionConfiguration {
    // Because on < iOS13 the configuration class gets copied and we can't simply compare it's the same instance, we need to
    // provide custom implementation for comparing. The default `Equatable` implementation of `URLSessionConfiguration`
    // simply compares the pointers.
    @available(iOS, deprecated: 12.0, message: "Remove this workaround when dropping iOS 12 support.")
    func isTestEqual(to otherConfiguration: URLSessionConfiguration) -> Bool {
        let commonEquatability = identifier == otherConfiguration.identifier
            && requestCachePolicy == otherConfiguration.requestCachePolicy
            && timeoutIntervalForRequest == otherConfiguration.timeoutIntervalForRequest
            && timeoutIntervalForResource == otherConfiguration.timeoutIntervalForResource
            && networkServiceType == otherConfiguration.networkServiceType
            && allowsCellularAccess == otherConfiguration.allowsCellularAccess
            && httpShouldUsePipelining == otherConfiguration.httpShouldUsePipelining
            && httpShouldSetCookies == otherConfiguration.httpShouldSetCookies
            && httpCookieAcceptPolicy == otherConfiguration.httpCookieAcceptPolicy
            && httpAdditionalHeaders as? [String: String] == otherConfiguration.httpAdditionalHeaders as? [String: String]
            && httpMaximumConnectionsPerHost == otherConfiguration.httpMaximumConnectionsPerHost
            && httpCookieStorage == otherConfiguration.httpCookieStorage
            && urlCredentialStorage == otherConfiguration.urlCredentialStorage
            && urlCache == otherConfiguration.urlCache
            && shouldUseExtendedBackgroundIdleMode == otherConfiguration.shouldUseExtendedBackgroundIdleMode
            && waitsForConnectivity == otherConfiguration.waitsForConnectivity
            && isDiscretionary == otherConfiguration.isDiscretionary
            && sharedContainerIdentifier == otherConfiguration.sharedContainerIdentifier
            && waitsForConnectivity == otherConfiguration.waitsForConnectivity
            && isDiscretionary == otherConfiguration.isDiscretionary
            && sharedContainerIdentifier == otherConfiguration.sharedContainerIdentifier

        #if os(iOS)
        return commonEquatability
            && multipathServiceType == otherConfiguration.multipathServiceType
            && sessionSendsLaunchEvents == otherConfiguration.sessionSendsLaunchEvents
        #else
        return commonEquatability
        #endif
    }
}
