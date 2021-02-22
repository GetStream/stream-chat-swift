// LINK: https://getstream.io/chat/docs/ios-swift/ios_client_setup/?preview=1&language=swift#3.-setup-a-custom-dispatch-queue-for-responses:

import StreamChat

private var controller: ChatChannelController!

func snippet_ux_client_setup_custom_dispatchqueue() {
    // > import StreamChat

    controller.callbackQueue = .global()
}
