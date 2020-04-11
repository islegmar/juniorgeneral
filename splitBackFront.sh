#!/bin/bash
# Split an image in back / front

# =================================================
# Variables
# =================================================
silent=0
tmpFile=/tmp/$(basename $0).$$
doPaste=0
inFile=""
outFile="" # Only if paster
posSplit=""
fileBack="back.png"
fileFront="front.png"
# TODO : calculate as a parameter
# 280px with a resolution of 330ppi (print) and scale 1/72 corresponds to a height of a person
# Of course no all those images are persons so this info we must or provide as parameter or from config
hInPx=280

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Split the image in a back and a front

SYNOPSIS
       `basename $0` [-s] [-p] -i file -k number [-B file] [-F file] [-o file]

DESCRIPTION
       Split vertically an image in two in the height done by -k so we get a front and back images
       The value of -k has been oobtained by getSplit.sh

       -p
              Paste back and front. If not, back and front are generated as separated files

       -i file
              Input file with the image that is going to be divided

       -k number
              Height where the image will be splitted

       -o file
              If paste, file with the final image

       -B file
              If not paste, file with the back image (def: $fileBack)

       -F file
              If not paste, file with the front image (def: $fileFront)
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $*
}

# =================================================
# Arguments
# =================================================
while getopts "hspi:o:k:F:B:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    p) doPaste=1 ;;
    i) inFile=$OPTARG ;;
    o) outFile=$OPTARG ;;
    k) posSplit=$OPTARG ;;
    F) fileFront=$OPTARG ;;
    B) fileBack=$OPTARG ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# --- Check Arguments
errors=""

if [[ -z "$inFile" ]]
then
  errors="${errors}A file must be specified. "
elif [[ ! -f "$inFile" ]]
then
  errors="${errors}File $inFile does not exist. "
fi

if [[ -z "$posSplit" ]]
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
rm ${tmpFile}* 2>/dev/null

if [ $doPaste -eq 1 ]
then
  convert $inFile -chop 0x${posSplit}+0+0 -resize x${hInPx} ${tmpFile}.back
  convert $inFile -crop 0x${posSplit}+0+0 -resize x${hInPx} ${tmpFile}.front

  w=$(identify -format "%w" ${tmpFile}.back)
  h=$(( $(identify -format "%h" ${tmpFile}.back)/10 ))
  #echo "w: $w, h: $h"
  convert -size "${w}x${h}" xc:"#4d2600" ${tmpFile}.basis.png
  #convert -crop "${w}x${h}+0+0" resources/mud.png ${tmpFile}.basis.png

  montage \
    ${tmpFile}.back  \
    ${tmpFile}.front \
    -tile 1x2 \
    -geometry +0+1 \
    -background gray \
    ${tmpFile}.bf

  montage \
    ${tmpFile}.basis.png \
    ${tmpFile}.bf  \
    ${tmpFile}.basis.png \
    -tile 1x3 \
    -geometry +0+0 \
    -background gray \
    $outFile
  trace "From $inFile created $outFile!"
else
  convert $inFile -chop 0x${posSplit}+0+0 -resize x${hInPx} $fileBack
  convert $inFile -crop 0x${posSplit}+0+0 -resize x${hInPx} $fileFront

  trace "Image $inFile split in front: $fileFront and back: $fileBack!"
fi

rm ${tmpFile}* 2>/dev/null
