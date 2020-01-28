## Example App

This repo includes a fully functional example app. You can run the example app by following these steps:

1. Make sure you have Xcode 11 installed and that it has latest components installed (open Xcode and install any pending update)
2. Download the StreamChat repo: `git clone git@github.com:GetStream/stream-chat-swift.git`
3. Change the directory: `cd stream-chat-swift/Example/Cocoapods`
4. Install the [Cocoapods](https://guides.cocoapods.org/using/getting-started.html): `sudo gem install cocoapods`
5. Install dependencies: `pod install --repo-update`

<details>
<p>
  
```sh
Analyzing dependencies
Downloading dependencies
Installing GzipSwift (5.0.0)
Installing Nuke (8.2.0)
Installing ReachabilitySwift (4.3.1)
Installing RxAppState (1.6.0)
Installing RxCocoa (5.0.1)
Installing RxGesture (3.0.1)
Installing RxRelay (5.0.1)
Installing RxSwift (5.0.1)
Installing SnapKit (5.0.1)
Installing Starscream (3.1.1)
Installing StreamChat (1.5.4)
Installing StreamChatCore (1.5.4)
Installing SwiftyGif (5.1.1)
Generating Pods project
Integrating client project
Pod installation complete! There are 2 dependencies from the Podfile and 13 total pods installed.
```
  
</p>
</details>

6. Open the project: `open ChatExample.xcworkspace`
67. Select `ChatExample` as an active scheme (if needed):

<img src="https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/example_app_active_scheme.jpg" width="690">

8. Click build and run.

<img src="https://raw.githubusercontent.com/GetStream/stream-chat-swift/master/docs/images/example_app.png" width="375">
