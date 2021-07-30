// LINK: https://getstream.io/chat/docs/ios-swift/ios_custom_data/?preview=1&language=swift#3.-define-the-following-typealiases-in-your-module

import StreamChat

func snippet_ux_custom_data_typealiases() {
    // > import StreamChat

    // Change this typealias to your custom data types
    typealias CustomExtraDataTypes = MyCustomExtraData // 👈 Your_Custom_Data_Type_Here 👈

    typealias ChatClient = _ChatClient<CustomExtraDataTypes>

    typealias ChatUser = _ChatUser<CustomExtraDataTypes.User>
    typealias CurrentChatUser = _CurrentChatUser<CustomExtraDataTypes.User>
    typealias ChatChannel = _ChatChannel<CustomExtraDataTypes>
    typealias ChatChannelRead = _ChatChannelRead<CustomExtraDataTypes>
    typealias ChatChannelMember = ChatChannelMember<CustomExtraDataTypes.User>
    typealias ChatMessage = _ChatMessage<CustomExtraDataTypes>

    typealias CurrentChatUserController = _CurrentChatUserController<CustomExtraDataTypes>
    typealias ChatChannelListController = _ChatChannelListController<CustomExtraDataTypes>
    typealias ChatChannelController = _ChatChannelController<CustomExtraDataTypes>
    typealias ChatMessageController = _ChatMessageController<CustomExtraDataTypes>
}

// types

private struct NameAndColorExtraData: ChannelExtraData {
    static var defaultValue: NameAndColorExtraData = .init()
}

private enum MyCustomExtraData: ExtraDataTypes {
    typealias Channel = NameAndColorExtraData
}
