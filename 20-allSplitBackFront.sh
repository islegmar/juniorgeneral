#!/bin/bash

[ ! -f $cfgFile ] && touch $cfgFile
cfgFile="config/images.txt"

cat<<EOD
=================================
- Read all the lines in $cfgFile (images/changed02)
- Split in back and front parts (folder specified in $cfgFile)
=================================
EOD
read

baseSrcDir="images/changed02/"
baseDstDir="images/final/pieces/"

# To keep spaces when reading lines
OLD_IFS=$IFS
IFS=''
fPattern="[^ ]*- ([^ ]*) *: *([^ ]*)"
declare -a path
while read -r line
do
  # File
  if [[ $line =~ $fPattern ]]
  then
    # eg. EnglishTroops-3-5-0
    fileName=${BASH_REMATCH[1]}
    type=${BASH_REMATCH[2]}
  
    # Calculate the dstFile
    dstDir="${baseDstDir}"
    for s in "${path[@]}"
    do
      dstDir="${dstDir}${s}/"
    done
    [ ! -d ${dstDir} ] && mkdir -p ${dstDir}
    dstFile="${dstDir}${fileName}.png"
  
    # Find the srcFile
    srcFile=$(find $baseSrcDir -type f -name "${fileName}.png")
    echo "Processing [$type] $dstFile ..."
    #echo "dstFile : $dstFile"

    splitBackFront.sh \
      -s \
      -i ${srcFile} \
      -o ${dstFile} \
      -t ${type}
  # Level
  else
    numSpaces=$(echo $line|sed -e 's/[^ ]*$//'|wc -c)
    frg=$(echo $line|sed -e 's/^ *//')
    level=$(($numSpaces/2))
    #echo "(level: $level) (frg: $frg) (line: $line)"
    path[$level]=${frg}
  fi
done < <( grep -v '^#' $cfgFile|grep -v '^ *$' )
IFS=$OLD_IFS

cat<<EOD
=================================
Front and back pieces generated in the folder specified by $cfgFile

NEXT : 40-genArmy.sh
=================================
EOD
