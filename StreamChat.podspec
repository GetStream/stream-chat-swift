Pod::Spec.new do |spec|
  spec.name = "StreamChat"
  spec.version = "1.0.5"
  spec.summary = "Stream iOS Chat"
  spec.description = "stream-chat-swift is the official Swift client for Stream Chat, a service for building chat applications."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "Alexey Bukhtin" => "alexey@getstream.io" }
  spec.social_media_url = "https://getstream.io"
  spec.swift_version = "5.0"
  spec.platform = :ios, "11.0"
  spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
  spec.requires_arc = true

  spec.source_files  = "Sources/**/*.swift"
  spec.resources = "Sources/Chat.xcassets"

  spec.framework = "Foundation", "UIKit"

  spec.dependency "Nuke", "~> 8.0"
  spec.dependency "SnapKit", "~> 5.0"
  spec.dependency "SwiftyGif", "~> 5.1"
  spec.dependency "Starscream", "~> 3.0"
  spec.dependency "ReachabilitySwift", "~> 4.3"
  spec.dependency "GzipSwift", "~> 5.0"

  spec.dependency "RxSwift", "~> 5.0"
  spec.dependency "RxAppState", "~> 1.5"
  spec.dependency "RxGesture", "~> 2.2"
end
