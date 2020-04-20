#!/bin/bash

cfgFile="config/images.txt"
[ ! -f $cfgFile ] && touch $cfgFile

tmpFile=/tmp/$(basename $0).$$

cat<<EOD
=================================
STEP 1:
- Get the big images (images/changed01)
- Split is small components (images/changed02)

STEP 2:
- Read all the lines in $cfgFile (reference to images/changed02)
- Complete the file $cfgFile
=================================
EOD
read

rm ${tmpFile}* 2>/dev/null

# --------------------------
# STEP 1 : split in components
# --------------------------
for f in $(find images/changed01 -type f )
do
  dir=$(echo ${f/changed01/changed02/}| sed -e 's/\.[^\.]*$//')

  if [ -d $dir ]
  then
    echo "Skipping $dir!"
  else
    echo "Processing $dir ..."
    mkdir -p $dir

    ./split.sh -s -i $f -d $dir
  fi
done

# --------------------------
# STEP 2 : complete config file
# --------------------------
for f in $(find images/changed02 -type f -name '*.png')
do
  shortFile=$(basename ${f} | sed -e 's#\.[^\.]*$##')

  if [ $(grep -c $shortFile $cfgFile) -eq 0 ]
  then
    echo "Add $shortFile in $cfgFile"
    echo "# - ${shortFile} : " >> $tmpFile
  fi
done

[ -f $tmpFile ] && sort $tmpFile >>$cfgFile

cat<<EOD
=================================
- Check images/changed02 and remove the ones shouldn't keep
- Check $cfgFile and complete the info for the added lines (type and destination folder)

NEXT : 20-allSplitBackFront.sh to split figures in back and front
=================================
EOD

rm ${tmpFile}* 2>/dev/null
