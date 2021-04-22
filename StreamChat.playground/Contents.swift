import StreamChat

// ⚠️ This is a Stream internal playground for testing interactions with StreamChat.

let apiKeyString = "8br4watad788"

LogConfig.level = .debug

let client = ChatClient(
    config: .init(apiKeyString: apiKeyString),
    tokenProvider:
        // luke_skywalker
        .static("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0")
)

// // // // // // // // // // // // // // // // // //





















// // // // // // // // // // // // // // // // // //

import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
