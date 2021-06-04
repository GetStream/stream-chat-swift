#!/bin/bash

TARGET=$1

# Move to project root directory
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$scriptDir/../"

if [[ "$TARGET" = "StreamChat" ]];then
    TARGET_DIRECTORY="Sources/StreamChat"
elif [[ "$TARGET" = "StreamChatUI" ]]; then
    TARGET_DIRECTORY="Sources/StreamChatUI"
else
    echo "Please specify target to generate docs for (StreamChat or StreamChatUI)"
    exit 1
fi

OUTPUT_DIRECTORY="docusaurus/docs/iOS"

swift-doc generate $TARGET_DIRECTORY  -n $TARGET -o "$OUTPUT_DIRECTORY/$TARGET_DIRECTORY"

pushd $OUTPUT_DIRECTORY

# Delete emissions which cause docusaurus not compiling., we probably want to rename Home.md to name it contains it in order to create brief overview of the component.
find . -type f -name '_Sidebar.md' -delete
find . -type f -name 'Home.md' -delete
find . -type f -name '_Footer.md' -delete

popd

# cleanup the duplicate files by comparing what is not in the Sources directory.
bash Scripts/deleteDuplicates.sh "$OUTPUT_DIRECTORY/$TARGET_DIRECTORY" "$TARGET_DIRECTORY"

# Delete first lines in files
find "$OUTPUT_DIRECTORY/$TARGET_DIRECTORY" -type f -exec sed -i '' '1d' {} +

if [[ "$TARGET" = "StreamChatUI" ]]; then
   /bin/mv -v "$OUTPUT_DIRECTORY/$TARGET_DIRECTORY/"* "$OUTPUT_DIRECTORY/ui-components/"
   bash Scripts/addImagesToDocumentation.sh "$OUTPUT_DIRECTORY/ui-components"
else
    # Right now, we want to add documentation only for controllers.
    /bin/mv -v "$OUTPUT_DIRECTORY/$TARGET_DIRECTORY/Controllers/"* "$OUTPUT_DIRECTORY/controllers/"
fi

echo
# Delete unused sources which are not yet documented.
# TBD: Decide where to put those sources into docusaurus
#   rm -rf "$OUTPUT_DIRECTORY/Sources"

echo "Documentation for $TARGET generated successfully. Please do check $OUTPUT_DIRECTORY ui-components and controllers folder"

