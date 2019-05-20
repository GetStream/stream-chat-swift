Pod::Spec.new do |spec|
  spec.name         = "GetStreamChat"
  spec.version      = "0.1.2"
  spec.summary      = "Stream iOS Chat"
  
  spec.description  = <<-DESC
stream-chat-swift is the official Swift client for Stream Chat, a service for building chat applications.
DESC

  spec.homepage     = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "Alexey Bukhtin" => "alexey@getstream.io" }
  spec.social_media_url = "https://getstream.io"
  spec.swift_version = "5.0"
  spec.platform = :ios, "11.0"
  spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/**/*.swift"
  spec.resources = "Sources/GetStreamChat.xcassets"
  spec.framework = "Foundation", "UIKit"
  spec.dependency "RxSwift", "4.5.0"
  spec.dependency "RxCocoa", "4.5.0"
  spec.dependency "RxKeyboard", "0.9.0"
  spec.dependency "RxStarscream", "0.10"
  spec.dependency "RxReachability", "0.1.8"
  spec.dependency "RxAppState", "1.5.0"
  spec.dependency "RxGesture", "2.2.0"
  spec.dependency "SnapKit", "5.0.0"
  spec.dependency "Nuke", "7.6.3"
  spec.dependency "SwiftyGif", "5.1.1"
  spec.dependency "GzipSwift", "5.0.0"
  spec.requires_arc = true
end
