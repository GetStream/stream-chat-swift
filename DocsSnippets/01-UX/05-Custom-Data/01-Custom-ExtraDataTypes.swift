// LINK: https://getstream.io/chat/docs/ios-swift/ios_custom_data/?preview=1&language=swift#2.-use-the-type-in-your-custom-implementation-of-extradatatypes

import StreamChat

func snippet_ux_custom_data_extradatatypes() {
    // > import StreamChat
    
    /// Custom implementation of `ExtraDataTypes` with `NameAndColorExtraData`
    enum MyCustomExtraData: ExtraDataTypes {
        typealias Channel = NameAndColorExtraData

        // Note: Unless you specify other custom data types, the default data types are used.
    }
}

// types

private struct NameAndColorExtraData: ChannelExtraData {
    static var defaultValue: NameAndColorExtraData = .init()
}

private enum MyCustomExtraData: ExtraDataTypes {
    typealias Channel = NameAndColorExtraData
}
