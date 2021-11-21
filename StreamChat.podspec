Pod::Spec.new do |spec|
  spec.name = "StreamChat"
  spec.version = "4.5.0"
  spec.summary = "StreamChat iOS Client"
  spec.description = "stream-chat-swift is the official Swift client for Stream Chat, a service for building chat applications."

  spec.homepage = "https://getstream.io/chat/"
  spec.license = { :type => "BSD-3", :file => "LICENSE" }
  spec.author = { "getstream.io" => "support@getstream.io" }
  spec.social_media_url = "https://getstream.io"

  spec.swift_version = "5.2"
  spec.ios.deployment_target  = '11.0'
  spec.osx.deployment_target  = '10.15'
  spec.requires_arc = true

  spec.framework = "Foundation"
  spec.ios.framework = "UIKit"

  spec.source = { :http => "https://github.com/GetStream/stream-chat-swift/releases/download/#{spec.version}/#{spec.name}.xcframework.zip" }
  spec.vendored_frameworks = "#{spec.name}.xcframework"
  spec.preserve_paths = "#{spec.name}.xcframework/*"
end
