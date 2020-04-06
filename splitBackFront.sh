#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
file=""
split=""
fileBack="back.png"
fileFront="front.png"

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Split the image in a back and a front

SYNOPSIS
       `basename $0` [-s] -f file -k number [-B file] [-F file]

DESCRIPTION
       Split vertically an image in two in the height done by -k so we get a front and back images
       The value of -k has been oobtained by getSplit.sh

       -f file
              File with the image

       -k number
              Height where the image will be splitted

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
while getopts "hsf:k:F:B:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    f) file=$OPTARG ;;
    k) split=$OPTARG ;;
    F) front=$OPTARG ;;
    B) back=$OPTARG ;;
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
  errors="${errors}A file must be specified. "
elif [[ ! -f "$file" ]]
then
  errors="${errors}File $file does not exist. "
fi

if [[ -z "$split" ]]
then
  errors="${errors}A split value must be provided. "
fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================

# Get image size
w_h=`magick identify -format "%w %h" $file`
width=`echo $w_h|cut -d ' ' -f 1,1`
height=`echo $w_h|cut -d ' ' -f 2,2`

convert $file -crop ${width}x${split}+0+0  $fileFront
convert $file -crop ${width}x99+0+${split} $fileBack

echo "Image $file split in front: $fileFront and back: $fileBack!"
