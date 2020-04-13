#!/bin/bash
# Split an image in back / front
# About scape and resolution
# Given the type of army and the scale, which is the expected height in pixels so when printed
# they are properly scaled. For example, if we have an army of people (height:1.70 m) and we 
# want to print it in a printer (300ppi) with a scale 1/72 then the value will be 280
#
# 1.70 m => 17000 mm => (1/72) 23.6 mm => (1 inch = 25.4 mm) 0.93 inches => (300ppi) 278.9 pixels

# =================================================
# Constants
# =================================================
# Type of objects and its height in cm
TYPE_OF_OBJECTS="
man#180\n
man+#200\n
horse-spear#320\n
lancer#250\n
"
INCHES_TO_CM=2.54

# =================================================
# Variables
# =================================================
silent=0
tmpFile=/tmp/$(basename $0).$$
doPaste=0
inFile=""
posSplit=""           # Where image will be split
outFile=""            # Only if paste
colorBasis=""         # If specified, add basis
type="man"
hRealInCm=""
scale=$(echo "1/72"|bc -l)
resolution=300

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Split the image in a back and a front

SYNOPSIS
       `basename $0` [-s] [-p] -i file -o file [-k number] [-c color] [-t string] [-H number] [-S number] [-r number]

DESCRIPTION
       Split vertically an image in two in the height done by -k so we get a front and back images
       The value of -k has been oobtained by getSplit.sh

       -p
              Paste back and front. If not, back and front are generated as separated files

       -i file
              Input file with the image that is going to be divided

       -o file
              Output file. If no paste, two files will be generated for the front and back with the 
              suffix -front and -back

       -k number
              Height where the image will be splitted. If not specified, it will be divided in half

       -t string
              Type of object, so we get a "standard" height in cm bases in the following conversion table (def. $type)
              $(echo $TYPE_OF_OBJECTS)

       -H number
              Heigh in cm (alternative to type)

       -s number
              Scale used in the objects (1/72....) (def: $scale)

       -r number
              Resolution used (def: $resolution)

       -c color
             If specified, add a basis with this color (eg. #4d2600 for brown)
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $*
}

# =================================================
# Arguments
# =================================================
while getopts "hspi:o:k:c:t:S:r:H:" opt
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
    c) colorBasis=$OPTARG ;;
    t) type=$OPTARG ;;
    S) scale=$OPTARG ;;
    r) resolution=$OPTARG ;;
    H) hRealInCm=$OPTARG ;;
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

# if [[ -z "$posSplit" ]]
# then
#   errors="${errors}A split value must be provided. "
# fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================
rm ${tmpFile}* 2>/dev/null

# Calculate the number of pixels (height) the figure must have
# If not specified, get from its type
if [[ -z "$hRealInCm" ]]
then
  hRealInCm=$(echo -e $TYPE_OF_OBJECTS|grep -e "$type#"|cut -d '#' -f 2,2)
fi
hInIn=$(echo "${hRealInCm}*${scale}/$INCHES_TO_CM"|bc -l)
hInPx=$(echo "${hInIn}*${resolution}"|bc -l|sed -e 's/\..*$//')

# Split in two parts and scale to the desire height
if [ -z "$posSplit" ]
then
  posSplit=$(($(identify -format "%h" ${inFile})/2))
fi
trace "inFileW : $(identify -format "%w" ${inFile}), hInPx : ${hInPx}, posSplit: ${posSplit}"

# When cropping, if w not specified we have problems of back and front diffente width and not aligned, so
# better to specify explicit the width
# Height of both parts MUST be the same or when scaling they will have different heights
width=$(identify -format "%w" ${inFile})
convert $inFile -crop ${width}x${posSplit}+0+0!                   -resize x${hInPx} ${tmpFile}.front.png
convert $inFile -crop ${width}x${posSplit}+0+$((${posSplit}+1))!  -resize x${hInPx} ${tmpFile}.back.png

if [ $(identify -format "%w" ${tmpFile}.back.png) -ne  $(identify -format "%w" ${tmpFile}.front.png) ]
then
  cat<<EOD
=====================================================================================
ERROR splitting ${inFile}, width front/back are not the same!!"

wback  : $(identify -format "%w" ${tmpFile}.back.png) 
wfront : $(identify -format "%w" ${tmpFile}.front.png) 

image : $(identify ${inFile})
front : $(identify ${tmpFile}.front.png)
back  : $(identify ${tmpFile}.back.png)

hInPx    : ${hInPx} 
posSplit : ${posSplit}
=====================================================================================
EOD
  exit 2
fi


# TODO : do it with less steps using composite but ...
if [ ! -z "$colorBasis" ]
then
  # Create the basis
  w=$(identify -format "%w" ${tmpFile}.back.png)
  h=$(( $(identify -format "%h" ${tmpFile}.back.png)/4 ))

  convert -size "${w}x${h}" xc:"$colorBasis" ${tmpFile}.basis.png

  # Append the basis
  montage \
    ${tmpFile}.basis.png \
    ${tmpFile}.back.png \
    -tile 1x2 \
    -geometry +0+0 \
    -background white \
    ${tmpFile}.back.png

  montage \
    ${tmpFile}.front.png \
    ${tmpFile}.basis.png \
    -tile 1x2 \
    -geometry +0+0 \
    -background white \
    ${tmpFile}.front.png
fi

if [ $doPaste -eq 1 ]
then
  montage \
    ${tmpFile}.back.png  \
    ${tmpFile}.front.png \
    -tile 1x2 \
    -geometry +0+2 \
    -background gray \
    ${outFile}

  trace "From $inFile created $outFile!"
else
  fileBack=$(echo $outFile|sed -e "s#\(\.[^\.]*$\)#-back\1#")
  fileFront=$(echo $outFile|sed -e "s#\(\.[^\.]*$\)#-front\1#")
  cp  ${tmpFile}.back.png  $fileBack
  cp  ${tmpFile}.front.png $fileFront

  trace "Image $inFile split in front: $fileFront and back: $fileBack!"
fi

rm ${tmpFile}* 2>/dev/null
