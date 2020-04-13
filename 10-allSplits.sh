#!/bin/bash

cat<<EOD
=================================
Divide the images in images/changed01 in smaller components
and keep them in images/changed02
=================================
EOD
read

for f in $(find images/changed01 -type f )
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

cat<<EOD
=================================
Please take a look at images/changed02 to
see the new components

Next step : 20-allGetSplit.sh to find the split point between back & front
=================================
EOD
