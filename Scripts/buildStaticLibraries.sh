#!/usr/bin/env bash
#
# Usage: ./Scripts/buildStaticLibraries.sh
#
# This script creates static libraries for our libraries bundled in xcframeworks. 
# It also creates .bundle files that need to be copied for the libraries to work

products_path="Products"
derived_data="DerivedData"

archives="$products_path/Archives"
framework_path="$products_path/Library/Frameworks"

platforms=(
  "simulator"
  "os"
)

artifacts=(
  "StreamChatUI"
  "StreamChat"
)

library="StreamChatUI"
library_target=$library"Static"

mkdir -p DerivedData

for platform in ${platforms[@]}
do
  destination=""
  if [[ "$platform" == "os" ]]
  then
    destination="generic/platform=iOS"
  else
    destination="generic/platform=iOS Simulator"
  fi

  logs_file="$derived_data/build_static_libraries_iphone$platform-xcodebuild.log"
  echo "→ Creating archive for iphone$platform. Destination: $destination."
  echo "→ Building... Logs available: $logs_file"

  # We only archive StreamChatUI because since it has a dependency on StreamChat, it will build this one too.
  xcodebuild archive \
          -project StreamChat.xcodeproj \
          -scheme "$library_target" \
          -destination "$destination" \
          -derivedDataPath $derived_data \
          -archivePath "$archives/$library-iphone-$platform" \
          SKIP_INSTALL=NO \
          BUILD_LIBRARY_FOR_DISTRIBUTION=YES > $logs_file

  # Unlike `xcodebuild build`, `xcodebuild archive` does not generate a .swiftmodule for static libraries. So we manually
  # copy it from our local DerivedData
  #
  # Expanded explanation:
  # We cannot use `xcodebuild build` artifacts because those are build with the flag -fembed-bitcode-marker.
  # This is basically a "placeholder" to mark where bitcode should be added later. This means that its output does not include bitcode,
  # thus archiving an app with this library will fail.
  # `xcodebuild archive` uses the flag -fembed-bitcode, which will make sure bitcode is added.

  derived_data_products="DerivedData/Build/Intermediates.noindex/ArchiveIntermediates/$library_target/BuildProductsPath"
  archives_framework_path="$archives/$library-iphone-$platform.xcarchive/$framework_path"
  for artifact in ${artifacts[@]}
  do
    echo "→ Getting .swiftmodule for $artifact"
    cp -r "$derived_data_products/Release-iphone$platform/$artifact.swiftmodule/" "$archives_framework_path/$artifact.swiftmodule"
  done
done

for artifact in ${artifacts[@]}
do
  echo "→ Generating $artifact.xcframework"
  simulator_archive_path="$archives/$library-iphone-simulator.xcarchive/$framework_path"
  iphone_archive_path="$archives/$library-iphone-os.xcarchive/$framework_path"
  xcodebuild -create-xcframework \
    -library "$simulator_archive_path/lib$artifact.a" \
    -library "$iphone_archive_path/lib$artifact.a" \
    -output "Products/$artifact.xcframework"
done

mv $archives "$derived_data/Archives"
echo "→ XCFrameworks created in $products_path"

# Our libraries depend on resources. Those cannot be embedded in a static library, so we are manually creating the needed bundles.
# Those bundles need its content to be compiled.
echo "→ Creating StreamChat.bundle"

streamchat_bundle_path="$products_path/StreamChat.bundle"
xcdatamodeld_name="StreamChatModel"
xcdatamodeld_path="Sources/StreamChat/Database/$xcdatamodeld_name.xcdatamodeld"

mkdir $streamchat_bundle_path

# Compiles .xcdatamodeld into .mom
# Credits to CocoaPods https://github.com/CocoaPods/CocoaPods/blob/master/lib/cocoapods/generator/copy_resources_script.rb
xcrun momc $xcdatamodeld_path "$streamchat_bundle_path/$xcdatamodeld_name.momd"

echo "→ Creating StreamChatUIResources.bundle"

streamchatui_resources_path="Sources/StreamChatUI/Resources"
streamchatui_bundle_path="$products_path/StreamChatUIResources.bundle"
assets_path="$streamchatui_resources_path/Assets.xcassets/"

mkdir $streamchatui_bundle_path

# Compiles Assets.xcassets into Assets.car
xcrun actool --compile $streamchatui_bundle_path $assets_path \
  --platform "iphoneos" --minimum-deployment-target 11.0 \
  --output-format human-readable-text --notices --warnings > /dev/null

strings_folder_name="en.lproj"
strings_destination_folder="$streamchatui_bundle_path/$strings_folder_name"

cp -r "$streamchatui_resources_path/$strings_folder_name" $streamchatui_bundle_path

files=`find $strings_destination_folder -type f \( -iname \*.strings -o -iname \*.stringsdict \)`
for string_files in $files
do
  # Compiles .strings and .stringsdict files
  xcrun plutil -convert binary1 "$string_files"
done