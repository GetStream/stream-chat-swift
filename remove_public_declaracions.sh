args=("$@")
directory=$1

files=`find $directory -name "*.swift"`
for f in $files
do
	echo $f
	`sed -i '' -e 's/public //g' $f`
done