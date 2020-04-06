#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
file=""
tmpDir=/tmp/`basename $0`

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Get the height where to splñit the image

SYNOPSIS
       `basename $0` [-s] [-t dir] -f file

DESCRIPTION
       Get the value where we have to split vertically so we can get the front / back views
       Currently the process is manual : just split with several heights and MANUALLY chose one
       <SUMMARY>

       -f file
              File with the image

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
while getopts "hsf:t:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    f) file=$OPTARG ;;
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
  errors="${errors}A file must be specified. "
elif [[ ! -f "$file" ]]
then
  errors="${errors}File $file does not exist. "
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
w_h=`magick identify -format "%w %h" $file`
width=`echo $w_h|cut -d ' ' -f 1,1`
height=`echo $w_h|cut -d ' ' -f 2,2`

# Ok, start to cut to check where is the "middle"
let ini_h=(${height}/2)-10
for h in $(seq $ini_h $height)
do
  convert $file -crop ${width}x${h}+0+0 $tmpDir/$h.png
done

echo "Check images in $tmpDir!"

