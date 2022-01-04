//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

/// An option to enable ban users.
public enum BanEnabling {
    /// Disabled for everyone.
    case disabled
    
    /// Enabled for everyone.
    /// The default timeout in minutes until the ban is automatically expired.
    /// The default reason the ban was created.
    case enabled(timeoutInMinutes: Int?, reason: String?)
    
    /// Enabled for channel members with a role of moderator or admin.
    /// The default timeout in minutes until the ban is automatically expired.
    /// The default reason the ban was created.
    case enabledForModerators(timeoutInMinutes: Int?, reason: String?)
    
    /// The default timeout in minutes until the ban is automatically expired.
    public var timeoutInMinutes: Int? {
        switch self {
        case .disabled:
            return nil
            
        case let .enabled(timeout, _),
             let .enabledForModerators(timeout, _):
            return timeout
        }
    }
    
    /// The default reason the ban was created.
    public var reason: String? {
        switch self {
        case .disabled:
            return nil
            
        case let .enabled(_, reason),
             let .enabledForModerators(_, reason):
            return reason
        }
    }
    
    /// Returns true is the ban is enabled for the channel.
    /// - Parameter channel: a channel.
    public func isEnabled(for channel: ChatChannel) -> Bool {
        switch self {
        case .disabled:
            return false
            
        case .enabled:
            return true
            
        case .enabledForModerators:
            fatalError("Not implementated yet")
            //      let members = Array(channel.members)
            //      return members.first(where: { $0.user.isCurrent && ($0.role == .moderator || $0.role == .admin) }) != nil
        }
    }
}
