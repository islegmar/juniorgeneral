#!/bin/bash

cfgFile="config/images.csv"

cat<<EOD
=================================
Divide the images in images/changed02 several times
and keep them in config so we check the division point
Also add entries in $cfgFile
=================================
EOD
read

[ ! -f $cfgFile ] && touch $cfgFile

for f in $(find images/changed02 -type f -name '*.png')
do
  dir=$(echo ${f/images\/changed02/config/}| sed -e 's/\.[^\.]*$//')

  if [ -d $dir ]
  then
    echo "Skipping $dir!"
  else
    mkdir -p $dir

    ./getSplit.sh -f $f -t $dir
  fi

  if [ $(grep -c $f $cfgFile) -eq 0 ]
  then
    echo "Add $f in $cfgFile"
    echo "$f|" >> $cfgFile
  fi

done

cat<<EOD
=================================
Go to config, find the division point and update 
the file $cfgFile MANUALLY

NEXT : 30-allSplitBackFront.sh
=================================
EOD
