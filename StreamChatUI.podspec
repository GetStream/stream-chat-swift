Pod::Spec.new do |spec|
    spec.name = "StreamChatUI"
    spec.version = "3.0-beta.1"
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
  
    spec.source_files  = "Sources_v3/StreamChatUI/**/*.swift"
    spec.exclude_files = ["Sources_v3/StreamChatUI/**/*_Tests.swift", "Sources_v3/StreamChatUI/**/*_Mock.swift"]
    spec.resource_bundles = {
        'StreamChatUI' => ["Sources_v3/StreamChatUI/Resources/**/*"]
    }
  
    spec.framework = "Foundation", "UIKit"
  
    spec.dependency "StreamChat", "~> 3.0-rc"
    spec.dependency "Nuke", "~> 9.0"
    spec.dependency "SwiftyGif", "~> 5.0"
  end
  