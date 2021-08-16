---
title: Migrating from 1.x and 2.x
---

StreamChat SDKs were re-written for the ground up for v3/v4. Unfortunately that means there isn't a clear, straightforward way to migrate. We suggest reading up on documentation and sample projects to get familiar with the SDK so that you can re-create the functionality with the new SDKs.

---
Please don't hesitate to contact us by sending an email to support@getstream.io or opening a ticket in our [github repo](https://github.com/GetStream/stream-chat-swift). We'll help you during your migration process and any issues you might face.

---

**Please don't upgrade to version 4.0 before you get familiar with the changes and their impact on your codebase.**

To prevent CocoaPods from updating `StreamChat` to version 4, you can explicitly pin the SDKs to versions 2.x in your `podfile`:
```ruby
pod 'StreamChat', '~> 2.0'
pod 'StreamChatCore', '~> 2.0' # if needed
pod 'StreamChatClient', '~> 2.0' # if needed
```

## Missing Features

Some features are missing from the new versions so if you're using these, please hold on to upgrade until they're implemented. We're constantly improving and adding new features and we don't expect this "transitioning phase" to last long. v4 will catch up to v2 in terms of features very soon.

If you're actively using one of these features, please hold off upgrading until we add these in.

* RxSwift wrappers
* Paginating reactions
* Message search

# StreamChat v1.x / v2.x -> StreamChatUI v4

None of the UI SDK components we had in v1.x / v2.x were carried over to StreamChatUI and it was written from the ground up. The new UI SDK is much more component-focused and each component can be used separately. Please check [UI Customization Guide](ui-customization.md) to get familiar on how to use it and convert your screens.

# StreamChatCore v1.x / v2.x and StreamChatClient v2.x -> StreamChat v4

Our low-level frameworks (`Client` + `Core`) were merged and renamed to `StreamChat`. If you use only our low-level frameworks, you can use our [Introduction page](../basics/getting-started) and [official docs](getstream.io/chat/docs/ios-swift) to get more familiar with the update API and better assess the impact of the changes on your codebase.
