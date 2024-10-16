---
title: Thread List
---

The `ChatThreadListView` is the UI component that displays the list of threads that the current user is participating in.

:::note
The Thread List component is available on the SwiftUI SDK since version [4.65.0](https://github.com/GetStream/stream-chat-swiftui/releases/tag/4.65.0).
:::

## Basic Usage

You can show this component in your app by creating a `ChatThreadListView` instance, here is a simple example of an app with two tabs, one for the channel list and another for the thread list:

```swift
struct ChatApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ChatChannelListView()
                    .tabItem { Label("Chat", systemImage: "message") }
                ChatThreadListView()
                    .tabItem { Label("Threads", systemImage: "text.bubble") }
            }
        }
    }
}
```

The `ChatThreadListView` has the following parameters:
- `viewFactory`: The view factory used for creating views used by the thread list.
- `viewModel`: The view model used for managing the thread list presentation logic. A default view model is provided if not specified.
- `threadListController`: The thread list controller managing the list of threads. A custom `ChatThreadListQuery` can be provided here to customize the list of threads.
- `title`: A custom title used as the navigation bar title.
- `embedInNavigationView`: A boolean indicating whether to embed the view in a `NavigationView` or not. The default is `true`.

