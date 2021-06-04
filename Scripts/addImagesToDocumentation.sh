#!/bin/bash

# Move to project root directory
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$scriptDir/../"

DOCUMENTATION_FOLDER=$1
PATH_TO_SNAPSHOTS="UISDKdocumentation/__Snapshots__"
PATH_TO_ASSETS="assets"
PATH_TO_DOCUSAURUS="docusaurus/docs/iOS"

# Let's iterate through snapshots we have and add them to the given components:
for UI_SNAPSHOT in ${PATH_TO_SNAPSHOTS}/*;do

    # Get component name for later processing and finding corresponding file in markdown.
    STRIPPED_PATH=`basename $UI_SNAPSHOT`
    COMPONENT_NAME=${STRIPPED_PATH%_*_*}
    DOCUMENTATION_FILE=`find $DOCUMENTATION_FOLDER -name "$COMPONENT_NAME.md"`

    # Let's use just light variation of the screenshot, we can support dark mode later.
    FINAL_SNAPSHOT=`ls $UI_SNAPSHOT | grep light`
    
    # Check if the file already contains snapshot line, if yes, continue the cycle and generate it for next one. s
    tail -1 "$DOCUMENTATION_FILE" | grep "$FINAL_SNAPSHOT"
    if [ $? -eq 0 ];then
        echo "There is already line containing the snapshot for $COMPONENT_NAME, skipping adding of documentation."
        continue
    fi
    
    echo "Copying $COMPONENT_NAME image to docusaurus/docs/iOS/assets/"
    pwd 
    cp "$UI_SNAPSHOT/$FINAL_SNAPSHOT" "$PATH_TO_DOCUSAURUS/$PATH_TO_ASSETS/$FINAL_SNAPSHOT"

    echo "Adding snapshot of $COMPONENT_NAME to documentation..."
    # Docusaurus works only with relative paths, so we move to docusaurus root folder (iOS) and generate relative path for the 
    # snapshot aka ../../assets/Snapshot-light.png when the directory is /ui-components/Folder/Snapshot.md
    pushd "$PATH_TO_DOCUSAURUS"
    RELATIVE_PATH_INSIDE_DOCUSAURUS=`dirname ${DOCUMENTATION_FILE##*iOS/}`
    DESIRED_PATH=`realpath --relative-to="$RELATIVE_PATH_INSIDE_DOCUSAURUS" "$PATH_TO_ASSETS"`
    popd
    
    # Simple create image annotation and paste it to the first line of the file.
    SNAPSHOT_ANNOTATION_TEXT="![$COMPONENT_NAME]($DESIRED_PATH/$FINAL_SNAPSHOT)"
    echo -e "$SNAPSHOT_ANNOTATION_TEXT\n$(cat $DOCUMENTATION_FILE)" > $DOCUMENTATION_FILE

    if [ $? -eq 0 ];then
        echo "Successfully added documentation snapshot to $DOCUMENTATION_FILE"
    fi 
done
