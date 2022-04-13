Pod::Spec.new do |spec|
    spec.name = "StreamChatUI"
    spec.version = "4.2.0"
    spec.summary = "StreamChat UI Components"
    spec.description = "StreamChatUI SDK offers flexible UI components able to display data provided by StreamChat SDK."
  
    spec.homepage = "https://getstream.io/chat/"
    spec.license = { :type => "BSD-3", :file => "LICENSE" }
    spec.author = { "getstream.io" => "support@getstream.io" }
    spec.social_media_url = "https://getstream.io"
    spec.swift_version = "5.2"
    spec.platform = :ios, "11.0"
    spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
    spec.requires_arc = true
  
    spec.source_files = "Sources/StreamChatUI/**/*.swift"
    spec.exclude_files = ["Sources/StreamChatUI/**/*_Tests.swift", "Sources/StreamChatUI/**/*_Mock.swift"]
    spec.resource_bundles = { "StreamChatUI" => ["Sources/StreamChatUI/Resources/**/*"] }
    spec.resource = 'Sources/StreamChatUI/xibs/**/*'
    spec.framework = "Foundation", "UIKit"
  
    spec.dependency "StreamChat", "#{spec.version}"
    spec.dependency "Nuke", "~> 10.0"
    spec.dependency "SwiftyGif", "~> 5.4.1"
    spec.dependency "EFQRCode", "~> 6.2.0"
    spec.dependency "swiftScan"
    spec.dependency "SkeletonView", "1.29.2"
    spec.dependency "Stipop", "0.3.1"
    spec.dependency "Giphy", "2.1.21"
  end
