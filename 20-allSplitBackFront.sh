#!/bin/bash

[ ! -f $cfgFile ] && touch $cfgFile
cfgFile="config/images.csv"

cat<<EOD
=================================
- Read all the lines in $cfgFile (images/changed02)
- Split in back and front parts (folder specified in $cfgFile)
=================================
EOD
read

baseSrcDir="images/changed02"
while read -r line
do
  #echo "line : $line"
  # Example:
  # - file : www.juniorgeneral.org/mediaval/EnglishTroops/EnglishTroops-2-6-0-0.png|
  file="${baseSrcDir}/$(echo $line |cut -d '|' -f 1,1)"
  type=$(echo $line |cut -d '|' -f 2,2)
  dst=$(echo $line  |cut -d '|' -f 3,3)
  split=$(echo $line|cut -d '|' -f 4,4)

  # baseFile contains just the name of the file (no directory) without
  # extension so we can use it for building
  # the names of the front / back
  # - EnglishTroops-2-6-0-0
  baseFile=$(basename $file|sed -e 's#\..*##')

  if [ -z "$dst" ]
  then
    echo "No dst folder specified, ignore line $line!"
    continue
  fi

  dstDir="images/final/pieces/${dst}"

  # If already exist the files, skip it
  if [ $(ls -1 $dstDir/${baseFile}* 2>/dev/null|wc -l) -ne 0 ]
  then
    echo "Skip $file, already processes"
  else
    echo "Processing $file into $dstDir (type : $type)..."
    [ ! -d $dstDir ] && mkdir -p $dstDir

    # Split in half
    splitBackFront.sh \
      -s \
      -i $file \
      -o $dstDir/${baseFile}.png \
      -t $type 
    # # Height given
    # if [ -z "$(echo $type|sed -e 's/[0-9]//g')" ]
    # then
    #   splitBackFront.sh \
    #     -i $file \
    #     -o $dstDir/${baseFile}.png \
    #     -k $split \
    #     -H $type 
    # else
    #   splitBackFront.sh \
    #     -i $file \
    #     -o $dstDir/${baseFile}.png \
    #     -t $type 
    # fi
  fi
done < <( grep -v '^#' $cfgFile )

cat<<EOD
=================================
Front and back pieces generated in the folder specified by $cfgFile

NEXT : 40-genArmy.sh
=================================
EOD
