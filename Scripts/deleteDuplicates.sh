#!/bin/bash

# Move to project root directory
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$scriptDir/../"

# Let's delete the typealiases :)
pushd "docusaurus/docs/iOS"

echo "_Button.md 
_View.md
_Control.md
_CollectionReusableView.md
_CollectionViewCell.md
_NavigationBar.md
_ViewController.md" > /tmp/reservedFilesNotToRename.txt

# We find the files which are duplicate (For example _ChatChannelNamer and ChatChannelNamer), name without underscore in here is typealias.
find . -type f -name "_*" | sed 's/_//g' > /tmp/typealiasDuplicates.txt

while read TYPEALIAS_FILE; do
  rm -rf $TYPEALIAS_FILE         
  echo "REMOVED $TYPEALIAS_FILE typealias"                                    
done < /tmp/typealiasDuplicates.txt

# What lefts is to remove underscores from files, so let's iterate over files with underscore and rename them to no underscore
# Except for /tmp/reservedFilesNotToRename.txt :)
for file in `find . -type f -name "_*"`; do
   FILE_NAME=`basename $file`
   cat /tmp/reservedFilesNotToRename.txt | grep "$FILE_NAME"
   if [ $? -eq 0 ];then 
     echo "NOT RENAMING: $FILE_NAME"
     continue
   fi
   /bin/mv "$file" "${file/_}"
done;

popd


