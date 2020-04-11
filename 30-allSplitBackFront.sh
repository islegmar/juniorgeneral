#!/bin/bash

cfgFile=config/images.csv
while read -r line
do
  file=$(echo $line|cut -d '|' -f 1,1)
  split=$(echo $line|cut -d '|' -f 2,2)

  dir=$(echo ${file/changed02/changed03/}| sed -e 's#/[^\/]*$##')
  baseFile=$(basename $file|sed -e 's#\..*##')

  [ ! -d $dir ] && mkdir -p $dir

  #echo "$file : $split : $dir/${baseFile}.png"
  splitBackFront.sh \
    -p \
    -i $file \
    -k $split \
    -o $dir/${baseFile}.png 
done < $cfgFile
