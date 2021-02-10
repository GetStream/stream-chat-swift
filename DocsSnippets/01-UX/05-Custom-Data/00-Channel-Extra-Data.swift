// LINK: https://getstream.io/chat/docs/ios-swift/ios_custom_data/?preview=1&language=swift#1.-define-your-custom-channel-extra-data-type

import StreamChat

func snippet_ux_custom_data_channel_extra_data() {
    // > import StreamChat
    
    /// Your custom ChatChannel extra data type
    struct NameAndColorExtraData: ChannelExtraData {
        /// The value used when decoding the custom data type fails.
        static var defaultValue = NameAndColorExtraData(name: "Unknown", colorName: nil)
        
        let name: String
        let colorName: String?
    }
}
