Pod::Spec.new do |spec|
  spec.name = "StreamChat"
  spec.version = "4.0.0-beta.9"
  spec.summary = "StreamChat iOS Client"
  spec.description = "stream-chat-swift is the official Swift client for Stream Chat, a service for building chat applications."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"
  spec.swift_version = "5.2"

  spec.ios.deployment_target  = '11.0'
  spec.osx.deployment_target  = '10.15'

  spec.source = { :git => "https://github.com/GetStream/stream-chat-swift.git", :tag => "#{spec.version}" }
  spec.requires_arc = true

  spec.source_files  = "Sources/StreamChat/**/*.swift"
  spec.exclude_files = ["Sources/StreamChat/**/*_Tests.swift", "Sources/StreamChat/**/*_Mock.swift"]
  spec.resource_bundles = { "StreamChat" => ["Sources/StreamChat/**/*.xcdatamodeld"] }

  spec.framework = "Foundation"
  spec.ios.framework = "UIKit"

  spec.dependency "Starscream", "~> 4.0"
end
