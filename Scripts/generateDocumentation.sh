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

OUTPUT_DIRECTORY="docusaurus/docs/iOS/ReferenceDocs"

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

# Add snapshots to UI elements
if [[ "$TARGET" = "StreamChatUI" ]]; then
   bash Scripts/addImagesToDocumentation.sh "$OUTPUT_DIRECTORY/Sources/StreamChatUI"
fi

pushd docusaurus/docs/iOS/
# Let's go to output directory one more time and add MDX headers.
# --- 
# id: ${classname}
# header: ClassName
# --- 
# sed is cool and everything but having it on macOS hurts
find ReferenceDocs -type f > /tmp/allFiles.txt  

while read FILEPATH; do
 FILENAME=`basename $FILEPATH`
 #echo "Adding ID to: $FILEPATH"
 CLASSNAME="${FILENAME%.md}"
 LOWERCASED=$(echo $CLASSNAME | tr '[:upper:]' '[:lower:]')
 PATH_WITHOUT_FILE=`dirname $FILEPATH`

 #Docusaurus needs path for the ID...
 FINAL_PATH=$(echo "/$PATH_WITHOUT_FILE/$LOWERCASED" | sed 's#/#\\/#g')

 TITLESTRING="id: $LOWERCASED"
 FIRSTLINE=`head -1 "$FILEPATH"`

 # Got nothing better right now:
 if [ "$TITLESTRING" == "---" ]; then
    echo "Found id, title and slug marks, skipping"
    continue
 fi 

echo "FINAL_PATH:"
# FINAL_PATH=$(echo $FINAL_PATH | tr '[:upper:]' '[:lower:]')
echo $FINAL_PATH
    
sed -i '' "1s/^/---\nid: $LOWERCASED \ntitle: $CLASSNAME\nslug: $FINAL_PATH\n---\n/" $FILEPATH
done </tmp/allFiles.txt
popd

echo "Documentation for $TARGET generated successfully. Please do check $OUTPUT_DIRECTORY ui-components and controllers folder"