#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
file="army.png"
fileBack="back.png"
fileFront="front.png"
patternBack=""
patternFront=""
tmpDir=/tmp/`basename $0`

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Generates an army using a back and front images

SYNOPSIS
       `basename $0` [-s] [-o file] [-b file] [-f file] [-B pattern] [-F pattern] [-t dir]

DESCRIPTION
       Generates an army using a back and front images

       -o file
              File with the image containing the army (def: $file)

       -b file
              File with the back image (def: $fileBack)

       -f file
              File with the front image (def: $fileFront)

       -B pattern
              Pattern with the back images. If specified the files will be <pattern>-<num>.<ext>

       -F pattern
              Pattern with the back images. If specified the files will be <pattern>-<num>.<ext>

       -t dir
              Temporaty folder where the images will bew stored (def: $tmpDir)
EOF
}

# Generates a row of elements (with random) with back & front 
# - total : number of elements we have to chose
# - size  : number of elements we put in the row
# - file  : destination file
function genRow() {
  local total=$1
  local size=$2
  local file=$3

  # TODO 
  local tmpFile=$tmpDir/genRow.$$.png

  for(( col=0; col<$size; col++))
  do
    ind=$(( $RANDOM % $total ))

    # Put together back + front so we get one piece
    # The union line is a grey line so we can folde there
    montage \
      $tmpDir/back/$ind.png \
      $tmpDir/front/$ind.png \
      -tile 1x2 \
      -geometry +0+1 \
      -background gray \
      $tmpFile

    if [ $col -eq 0 ]
    then
      cp $tmpFile $file
    else
      montage \
        $file \
        $tmpFile \
        -tile 2x1 \
        -geometry +0+0 \
        -background white \
        $file
    fi
  done
}

# Taking a list of rows generated git genRow() create
# an army with them "glue together" with some terrain blocks
# - row_patten : pattern to "select" the rows (they will be sorted)
# - size       : total size, so we can make minor adjustments
function genArmy() {
}


# =================================================
# Arguments
# =================================================
while getopts "hso:t:f:b:F:B:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    o) file=$OPTARG ;;
    f) fileFront=$OPTARG ;;
    b) fileBack=$OPTARG ;;
    F) patternFront=$OPTARG ;;
    B) patternBack=$OPTARG ;;
    t) tmpDir=$OPTARG ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# --- Check Arguments
errors=""

if [[ -z "$file" ]]
then
  errors="${errors}A destination file  must be specified. "
fi

# if [[ -z "$fileFront" ]]
# then
#   errors="${errors}A file front must be specified. "
# fi
# 
# if [[ -z "$fileBack" ]]
# then
#   errors="${errors}A file back must be specified. "
# fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================
source ./funcs.sh

rebuildDir "$tmpDir"

# We have several fromnt/back images and we have to mix them. 
# They can have different sizes so we have to unify them
if [[ ! -z "$patternBack" && ! -z "$patternFront" ]]
then
  total=0
  maxW=0
  maxH=0

  # Check first the backs
  rebuildDir "$tmpDir/back"
  totBack=0
  for f in $(ls -1 $patternBack|sort)
  do
    cp $f $tmpDir/back/$totBack.png
    
    totBack=$(($totBack+1))
  done
  echo "totBack : $totBack"
  echo "Check $tmpDir/back"

  # Check first the front
  rebuildDir "$tmpDir/front"
  totFront=0
  for f in $(ls -1 $patternFront|sort)
  do
    cp $f $tmpDir/front/$totFront.png
    
    totFront=$(($totFront+1))
  done
  echo "totFront : $totFront"
  echo "Check $tmpDir/front"
  
  total=$totFront

  # Find max	
  maxW=$(ls -1 $tmpDir/back/* $tmpDir/front/*|xargs identify -format "%w\n"|sort -nr|head -n 1)
  maxH=$(ls -1 $tmpDir/back/* $tmpDir/front/*|xargs identify -format "%h\n"|sort -nr|head -n 1)

  echo "maxW : $maxW"
  echo "maxH : $maxH"

  # Generate the basis
  convert -size "${maxW}x$((${maxH}/2))" xc:"#4d2600" $tmpDir/basis.png
  convert -size "${maxW}x${maxH}"        xc:"#4d2600" $tmpDir/basis-extended.png

  # Resize all files
  for f in $(ls -1 $tmpDir/front/*)
  do
    echo "Converting $f ..."
    w=$(identify -format "%w" $f)
    convert -size ${w}x${maxH} xc:white $f -gravity south -composite $f
  done

  for f in $(ls -1 $tmpDir/back/*)
  do
    echo "Converting $f ..."
    w=$(identify -format "%w" $f)
    convert -size ${w}x${maxH} xc:white $f -gravity north -composite $f
  done

  for(( row=0; row<3; row++))
  do
    tmpFile=$tmpDir/row_${row}.png
    genRow $total 10 $tmpFile
  done

  genArmy "$tmpDir/row_*.png"
  
    if [ $row -eq 0 ]
    then
      cp $tmpFile $file
    else
      # Add the new row
      montage \
        $file \
        $tmpDir/basis-extended.png \
        $tmpFile \
        -tile 1x3 \
        -geometry +0+0 \
        -background white \
        $file
    fi
  done
else
  # Get image size
  # TODO : what to do if front/with are not equal in size?
  w_h=`magick identify -format "%w %h" $fileFront`
  width=`echo $w_h|cut -d ' ' -f 1,1`
  height=`echo $w_h|cut -d ' ' -f 2,2`
  
  # Generate the basis
  convert -size "${width}x$((${height}/2))" xc:"#4d2600" $tmpDir/basis.png
  convert -size "${width}x${height}"        xc:"#4d2600" $tmpDir/basis-extended.png
  
  # In case there is transparency (maybe we have "removed" the small basis that comes with the 
  # figure), remove it in the back/front with white
  convert $fileFront -background white -alpha remove -alpha off $tmpDir/front.png
  convert $fileBack  -background white -alpha remove -alpha off $tmpDir/back.png
  
  # Put together back + front so we get one piece
  # The union line is a grey line so we can folde there
  montage \
    $tmpDir/back.png \
    $tmpDir/front.png \
    -tile 1x2 \
    -geometry +0+1 \
    -background gray \
    $tmpDir/back_front.png
  
  # Montage one column
  montage \
    $tmpDir/basis-extended.png \
    $tmpDir/back_front.png \
    $tmpDir/basis.png \
    $tmpDir/back_front.png \
    $tmpDir/basis-extended.png \
    -tile 1x5 \
    -geometry +0+0 \
    -background white \
    $tmpDir/one_col.png
  
  # Montage the army
  montage \
    $tmpDir/one_col.png \
    $tmpDir/one_col.png \
    $tmpDir/one_col.png \
    -tile 3x1 \
    -geometry +0+0 \
    -background white \
    $file
  
  echo "Image $file created!"
fi
