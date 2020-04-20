#!/bin/bash

# -------------
# English
# -------------
baseSrcDir="images/final/pieces/mediaval/english"

cat<<EOD
================================================================================

Mediaval > English

================================================================================

EOD

[ ! -d images/final/armies/mediaval ] && mkdir -p images/final/armies/mediaval

defOpts=`cat<<EOD
  -t 2 \
  -c 2 \
  -C 80 \
  -L white \
  -r 3 \
  -R 200 \
  -O #f5f5f5 \
  -N 100 \
  -S 100 \
  -B #f5f5f5
EOD`

# echo "Building knights ..."
# ./genArmy.sh \
#   -s \
#   -w 4 \
#   -r 2 \
#   -o images/final/armies/mediaval/english-knights.png \
#   $( find images/final/pieces/mediaval/knights/ -name 'English*front*' -type f )
# 
echo ">>>> Building men-at-arms ..."
./genArmy.sh \
  ${defOpts} \
  -o images/final/armies/mediaval/english-men-at-arms.png \
  $( find images/final/pieces/mediaval/english/men-at-arms/ -name '*front*' -type f )

echo ">>>> Building leaves ..."
./genArmy.sh \
  ${defOpts} \
  -o images/final/armies/mediaval/english-leaves.png \
  $( find images/final/pieces/mediaval/english/leaves/ -name '*front*' -type f )

# Echo "Building archers ..."
# # Because the figures, the "rows" are "cols" and viceversa.
# # For a 4 inches (1200 px) basis:
# # - 2 rows, separated by 50cm => 80px
# # - 5 cols, separated by 1.8m => 300px
# ./genArmy.sh \
#   -c 2 \
#   -r 3 \
#   -C 80 \
#   -R 600 \
#   -o images/final/armies/mediaval/english-archers.png \
#   $( find ${baseSrcDir}/archers/ -name '*front*' -type f )

cat<<EOD
--------------------------------------------------------------------------------
$(ls -1 images/final/armies/mediaval/english-*)
--------------------------------------------------------------------------------
EOD
