//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// Signifies that a conformer will provide `name` and `imageURL` properties.
/// Used for `ChatUIUser` and `ChatUIChannel` types, where a `name` and `imageURL`
/// is required to render the models.
protocol ProvidesNameAndImage {
    var name: String? { get }
    var imageURL: URL? { get }
}

extension _ChatUser: ProvidesNameAndImage {
    var name: String? {
        if let extraData = extraData as? NameAndImageExtraData {
            return extraData.name
        }
        return nil
    }
    
    var imageURL: URL? {
        if let extraData = extraData as? NameAndImageExtraData {
            return extraData.imageURL
        }
        return nil
    }
}

/// Base class for `ChatUIUser`s that will be used in the SDK.
/// Defines the basic properties of a user.
/// WARNING: Not meant to be subclassed or used directly.
// QUESTION: How to prevent subclassing this?
open class ChatUIUserModel {
    /// The unique identifier of the user.
    public let id: UserId
    
    /// An indicator whether the user is online.
    public let isOnline: Bool
    
    /// An indicator whether the user is banned.
    public let isBanned: Bool
    
    /// An indicator whether the user is flagged by the current user.
    ///
    /// - Note: Please be aware that the value of this field is not persisted on the server,
    /// and is valid only locally for the current session.
    public let isFlaggedByCurrentUser: Bool
    
    /// The role of the user.
    public let userRole: UserRole
    
    /// The date the user was created.
    public let userCreatedAt: Date
    
    /// The date the user info was updated the last time.
    public let userUpdatedAt: Date
    
    /// The date the user was last time active.
    public let lastActiveAt: Date?
    
    /// Teams the user belongs to.
    ///
    /// You need to enable multi-tenancy if you want to use this, else it'll be empty. Refer to
    /// [docs](https://getstream.io/chat/docs/multi_tenant_chat/?language=swift) for more info.
    public let teams: [String]
    
    init<ExtraData: UserExtraData>(user: _ChatUser<ExtraData>) {
        id = user.id
        isOnline = user.isOnline
        isBanned = user.isBanned
        isFlaggedByCurrentUser = user.isFlaggedByCurrentUser
        userRole = user.userRole
        userCreatedAt = user.userCreatedAt
        userUpdatedAt = user.userUpdatedAt
        lastActiveAt = user.lastActiveAt
        teams = user.teams
    }
}

extension ChatUIUserModel: Hashable {
    public static func == (lhs: ChatUIUserModel, rhs: ChatUIUserModel) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Subclass this if you're using custom extra data in StreamChat SDK.
/// ```
///  // Step 0: (For StreamChat SDK) You implement your own UserExtraData
/// struct MyCustomExtraData: UserExtraData {
///     static var defaultValue: MyCustomExtraData = .init(info: "#")
///
///     let info: String
/// }
///
///  // Step 1: Subclass `ChatUIUser` and implement `init(user: _ChatUser<MyCustomExtraData>)`
/// class MyCustomChatUIUser: ChatUIUser {
///     let info: String
///
///     public required init<ExtraData: UserExtraData>(user: _ChatUser<ExtraData>, name: String?, imageURL: URL?) {
///         // The force cast will always succeed if everything is setup correctly
///         let extraData = user.extraData as! MyCustomExtraData
///         info = extraData.info
///         super.init(user: user, name: name, imageURL: imageURL)
///     }
/// }
///
///  // Step 2: Register your subclass so you receive it in views
/// UIModelConfig.default.userModelType = MyCustomChatUIUser.self
///
///  // Step 3: Use your subclass freely in views where applicable
/// class CustomUserView: UserView {
///     override func load(user: ChatUIUser) {
///          if let myCustomUser = user as? MyCustomChatUIUser {
///              // Do the custom stuff here
///              doStuff(with: myCustomUser.info)
///          }
///          super.load(user: user)
///     }
/// ```
// QUESTION: How to avoid force cast in custom user model init?
open class ChatUIUser: ChatUIUserModel, ProvidesNameAndImage {
    let name: String?
    let imageURL: URL?
    
    public required init<ExtraData: UserExtraData>(user: _ChatUser<ExtraData>, name: String?, imageURL: URL?) {
        self.name = name
        self.imageURL = imageURL
        super.init(user: user)
    }
}

// MARK: - TESTING

// Step 0: (For StreamChat SDK) You implement your own UserExtraData
struct MyCustomExtraData: UserExtraData {
    static var defaultValue: MyCustomExtraData = .init(info: "#")

    let info: String
}

// Step 1: Subclass `ChatUIUser` and implement `init(user: _ChatUser<MyCustomExtraData>)`
class MyCustomChatUIUser: ChatUIUser {
    let info: String
    
    public required init<ExtraData: UserExtraData>(user: _ChatUser<ExtraData>, name: String?, imageURL: URL?) {
        let extraData = user.extraData as! MyCustomExtraData
        info = extraData.info
        // User doesn't have to forward name and imageURL directly, they can provide custom values here
        super.init(user: user, name: name, imageURL: imageURL)
    }
}

struct MyReactionExtraData: MessageReactionExtraData {
    static var defaultValue: MyReactionExtraData = .init(isUpvote: false)
    
    let isUpvote: Bool
}

struct MyMessageExtraData: MessageExtraData {
    static var defaultValue: MyMessageExtraData = .init(isMsgFromGf: false)
    
    let isMsgFromGf: Bool
}

enum MyExtraDataTypes {
    typealias User = MyCustomExtraData
    typealias Message = MyMessageExtraData
    typealias MessageReaction = MyReactionExtraData
}

class MyCustomMessageReaction: ChatUIMessageReaction {
    let isUpvote: Bool
    
    public required init<ExtraData: ExtraDataTypes>(
        config: UIModelConfig = .default,
        reaction: _ChatMessageReaction<ExtraData>
    ) {
        let extraData = reaction.extraData as! MyReactionExtraData
        isUpvote = extraData.isUpvote
        super.init(config: config, reaction: reaction)
    }
}

class MyCustomMessage: ChatUIMessage {}

func registerTypes() {
    UIModelConfig.default.userModelType = MyCustomChatUIUser.self
    UIModelConfig.default.reactionModelType = MyCustomMessageReaction.self
}
