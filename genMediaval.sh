#!/bin/bash

# -------------
# English
# -------------
cat<<EOD
================================================================================

Mediaval > English

================================================================================

EOD

echo "Building knights ..."
./genArmy.sh \
  -s \
  -r 2 \
  -o images/final/mediaval/army-english-knights.png \
  $( find images/final/mediaval/knights/ -name 'English*front*' -type f )

echo "Building men-at-arms ..."
./genArmy.sh \
  -s \
  -r 3 \
  -o images/final/mediaval/army-english-men-at-arms.png \
  $( find images/final/mediaval/men-at-arms/ -name 'English*front*' -type f )

echo "Building leaves ..."
./genArmy.sh \
  -s \
  -r 3 \
  -o images/final/mediaval/army-english-leaves.png \
  $( find images/final/mediaval/leaves/ -name 'English*front*' -type f )

echo "Building archers ..."
./genArmy.sh \
  -s \
  -r 3 \
  -o images/final/mediaval/army-english-archers.png \
  $( find images/final/mediaval/archers/ -name 'English*front*' -type f )

cat<<EOD
--------------------------------------------------------------------------------
$(ls -1 images/final/mediaval/army-english-*)
--------------------------------------------------------------------------------
EOD
