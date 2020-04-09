#!/bin/bash

for f in $(find images/changed01 -type f)
do
  dir=$(echo ${f/changed01/changed02/}| sed -e 's/\.[^\.]*$//')

  if [ -d $dir ]
  then
    echo "Skipping $dir!"
  else
    mkdir -p $dir

    ./split.sh -i $f -d $dir
  fi
done
