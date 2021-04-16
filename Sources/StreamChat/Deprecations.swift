//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public extension _ChatChannel {
    /// A list of locally cached members objects.
    ///
    /// - Important: This list doesn't have to contain all members of the channel. To access the full list of members, create
    /// a `ChatChannelController` for this channel and use it to query all channel members.
    ///
    @available(*, renamed: "lastActiveMembers")
    var cachedMembers: Set<_ChatChannelMember<ExtraData.User>> { Set(lastActiveMembers) }
    
    /// A list of channel members currently online actively watching the channel.
    ///
    /// - Important: This list doesn't have to contain all members of the channel. To access the full list of watchers, create
    /// a `ChatChannelController` for this channel and use it to query all channel watchers.
    ///
    /// - Note: This property will contain no more than 25 watchers
    @available(*, renamed: "lastActiveWatchers")
    var watchers: Set<_ChatUser<ExtraData.User>> { Set(lastActiveWatchers) }
}

public extension _ChatMessage {
    /// Quoted message id.
    ///
    /// If message is inline reply this property will contain id of the message quoted by this reply.
    ///
    @available(*, deprecated, message: "Use quotedMessage?.id instead")
    var quotedMessageId: MessageId? { quotedMessage?.id }
}

public extension Logger {
    /// Stops program execution with `Swift.assertionFailure`. In RELEASE builds only
    /// logs the failure.
    ///
    /// - Parameters:
    ///   - message: A custom message to log if `condition` is evaluated to false.
    @available(*, deprecated, renamed: "assertionFailure")
    func assertationFailure(
        _ message: @autoclosure () -> Any,
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: UInt = #line
    ) {
        assertionFailure(message(), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
}
