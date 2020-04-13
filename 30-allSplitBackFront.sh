#!/bin/bash

cat<<EOD
=================================
Read all the lines in $cfgFile (do reference to images/changed02),
split in back and front and store the parts in images/changed03
=================================
EOD
read

cfgFile=config/images.csv
while read -r line
do
  # Example:
  # - file : images/changed02/www.juniorgeneral.org/mediaval/EnglishTroops/EnglishTroops-2-6-0-0.png
  file=$(echo $line|cut -d '|' -f 1,1)
  split=$(echo $line|cut -d '|' -f 2,2)
  type=$(echo $line|cut -d '|' -f 3,3)
  dst=$(echo $line|cut -d '|' -f 4,4)

  # baseFile contains just the name of the file (no directory) without
  # extension so we can use it for building
  # the names of the front / back
  # - EnglishTroops-2-6-0-0
  baseFile=$(basename $file|sed -e 's#\..*##')

  # dstDir is the destination folder
  # - images/changed03//www.juniorgeneral.org/mediaval/EnglishTroops
  if [ -z "$dst" ]
  then
    dstDir=$(echo ${file/changed02/changed03/}| sed -e 's#/[^\/]*$##')
  else
    dstDir="images/final/armies/${dst}"
  fi

  # If already exist the files, skip it
  if [ $(ls -1 $dstDir/${baseFile}* 2>/dev/null|wc -l) -ne 0 ]
  then
    echo "Skip $file, already processes"
  else
    echo "Processing $file into $dstDir ..."
    [ ! -d $dstDir ] && mkdir -p $dstDir

    # Height given
    if [ -z "$(echo $type|sed -e 's/[0-9]//g')" ]
    then
      splitBackFront.sh \
        -s \
        -i $file \
        -o $dstDir/${baseFile}.png \
        -k $split \
        -H $type 
    else
      splitBackFront.sh \
        -s \
        -i $file \
        -o $dstDir/${baseFile}.png \
        -t $type 
    fi
  fi
done < <( grep -v '^#' $cfgFile )

cat<<EOD
=================================
NEXT : 40-genArmy.sh
=================================
EOD
