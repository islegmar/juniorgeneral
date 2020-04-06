#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
file="army.png"
fileBack="back.png"
fileFront="front.png"
tmpDir=/tmp/`basename $0`

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Generates an army using a back and front images

SYNOPSIS
       `basename $0` [-s] [-f file] [-B file] [-F file] [-t dir]

DESCRIPTION
       Generates an army using a back and front images

       -f file
              File with the image containing the army (def: $file)

       -B file
              File with the back image (def: $fileBack)

       -F file
              File with the front image (def: $fileFront)

       -t dir
              Temporaty folder where the images will bew stored (def: $tmpDir)
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $*
}

# =================================================
# Arguments
# =================================================
while getopts "hsf:t:F:B:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    f) file=$OPTARG ;;
    F) front=$OPTARG ;;
    B) back=$OPTARG ;;
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

if [[ -z "$fileFront" ]]
then
  errors="${errors}A file front must be specified. "
fi

if [[ -z "$fileBack" ]]
then
  errors="${errors}A file back must be specified. "
fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================

[ -d $tmpDir ] && rm -fR $tmpDir
[ ! -d $tmpDir ] && mkdir -p $tmpDir

# Get image size
# TODO : what to do if front/with are not equal in size?
w_h=`magick identify -format "%w %h" $fileFront`
width=`echo $w_h|cut -d ' ' -f 1,1`
height=`echo $w_h|cut -d ' ' -f 2,2`

# Generate the basis
convert -size "${width}x$((${height}/2))" xc:"#4d2600" $tmpDir/basis.png
convert -size "${width}x${height}"        xc:"#4d2600" $tmpDir/basis-extended.png

# Remove transparency in the back/front with white
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

# Momntaghe one column
montage \
  $tmpDir/basis-extended.png \
  $tmpDir/back_front.png \
  $tmpDir/basis.png \
  $tmpDir/back_front.png \
  $tmpDir/basis-extended.png \
  -tile 1x5 \
  -geometry +0+0 \
  -background gray \
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

