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
patternFullImage=""
# TODO : remove => now it is used in splitBackFront so we already get
# the images in the scale we want (1/72)
hInPx="280"
tmpDir=/tmp/$(basename $0)
# Reize allowed im the images (in %)
resizeLessPerc=90
resizeMorePerc=110

# TODO : this should be a parameter but let's suppose the final canvas is 
# an A4 8.27 × 11.69 inches with resolution 300 ppi (we leave some borders)
resolution=300
canvasW=$(echo "8.27*$resolution"|bc -l)
canvasH=$(echo "11.69*$resolution"|bc -l)
# In pixels, we want to leave 1 cm more or less that with a resolution 300ppi
# than means 100px
borderCanvas=20
# Border in the image (px)
imageBorder=10

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Generates an army using a back and front images 

SYNOPSIS
       `basename $0` [-s] [-o file] [-b file] [-f file] [-B pattern] [-F pattern] [-t dir] [-H number]

DESCRIPTION
       Generates an army in two modes:
       + If B / F is given : put them together to make the figures with back and front, glue together 
         to make rows and glue rows together to make the army
       + If S is given : get random figures and fill the entire page with it

       -o file
              Output file with the image containing the army (def: $file)

       -b file
              File with the back image (def: $fileBack)

       -f file
              File with the front image (def: $fileFront)

       -B pattern
              Pattern with the back images. If specified the files will be <pattern>-<num>.<ext>

       -F pattern
              Pattern with the back images. If specified the files will be <pattern>-<num>.<ext>

       -S pattern
              Pattern with the full images

       -H number
              Given the type of army and the scale, which is the expected height in pixels so when printed
              they are properly scaled. For example, if we have an army of people (height:1.70 m) and we 
              want to print it in a printer (300ppi) with a scale 1/72 then the value will be 280

              1.70 m => 17000 mm => (1/72) 23.6 mm => (1 inch = 25.4 mm) 0.93 inches => (300ppi) 278.9 pixels

              TODO : let make the calcul for us specifying
              - Desire height (def: 1.70m)
              - Scale (def: 1/72)
              - Resolution (def: 300)

       -t dir
              Temporaty folder where the images will bew stored (def: $tmpDir)
EOF
}

# TODO : patillero
function roundValue() {
  echo $( echo $*|bc -l|sed -e 's/\..*$//')
}

# Give a list of files, return the max W and H
function getMaxW() {
  echo $(ls -1 $* |xargs identify -format "%w\n"|sort -nr|head -n 1)
}

function getMaxH() {
  echo $(ls -1 $* |xargs identify -format "%h\n"|sort -nr|head -n 1)
}

function getRandomImage() {
  local file=$1
  local border=$2
  shift 3
  local images=$*

  # Pick a random image
  local total=$(echo $images|wc -w)
  local ind=$(( $RANDOM % $total ))
  local image=$( echo $images|cut -d ' ' -f $(($ind+1)),$(($ind+1)) )

  # Random resize between [resizeLessPerc, resizeMorePerc]
  local resize=$(( ($RANDOM % ($resizeMorePerc-$resizeLessPerc))+$resizeLessPerc ))

  # Final image = resize + border
  convert -resize ${resize}% -border $border -bordercolor white $image $file
}

# Generates a row of elements (with random) with back & front 
# - total : number of elements we have to chose
# - size  : number of elements we put in the row
# - file  : destination file
# In case there is transparency (maybe we have "removed" the small basis that comes with the 
# figure), remove it in the back/front with white
#convert $fileFront -background white -alpha remove -alpha off $tmpDir/front.png
#convert $fileBack  -background white -alpha remove -alpha off $tmpDir/back.png
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
  local file=$1
  shift 
  local fRows=$*
  
  trace "Generating army ..."
  # Generate the basis
  maxW=$(getMaxW $fRows)
  maxH=$(getMaxH $fRows)

  #convert -size "${maxW}x$((${maxH}/4))" xc:"#4d2600" $tmpDir/basis.png
  #convert -size "${maxW}x$((${maxH}/4))" xc:"#4d2600" $tmpDir/basis.png
  
  echo "Terrain : $maxW" 
  convert -resize ${maxW}x -crop "${maxW}x$((${maxH}/4))"+0+0 resources/mud.png $tmpDir/basis.png
  convert -resize ${maxW}x -crop "${maxW}x$((${maxH}/2))"+0+0 resources/mud.png $tmpDir/basis-extended.png

  let ind=0
  for fRow in $fRows
  do
    if [ $ind -eq 0 ]
    then
      montage \
        $fRow \
        $tmpDir/basis.png \
        -tile 1x2 \
        -geometry +0+0 \
        -background white \
        $file
    else
      montage \
        $fRow \
        $tmpDir/basis-extended.png \
        $file \
        -tile 1x3 \
        -geometry +0+0 \
        -background white \
        $file
    fi

    ind=$(($ind+1))
  done

  montage \
    $tmpDir/basis.png \
    $file \
    -tile 1x2 \
    -geometry +0+0 \
    -background white \
    $file
}


# =================================================
# Arguments
# =================================================
while getopts "hso:t:f:b:F:B:H:S:" opt
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
    S) patternFullImage=$OPTARG ;;
    H) hInPx=$OPTARG ;;
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

# Generate random images from a list and put "as much as possible" in a canvas
if [ ! -z "$patternFullImage" ]
then
  images=$(find $patternFullImage -type f -name '*.png')

  # Now generate random images and add them
  # TODO : sure this can be done with less temporary files but ...
  freeH=$(roundValue "${canvasH}-2*${borderCanvas}")
  for((row=0; ; row++))
  do
    echo "Building row $row (free : $freeH) ..."
    tmpRowImg=$tmpDir/image_${row}.png

    freeW=$(roundValue "${canvasW}-2*${borderCanvas}")
    for((col=0; ; col++))
    do
      #echo "col:$col, freeW:$freeW..."
      tmpImg=$tmpDir/image_${row}_${col}.png
      getRandomImage $tmpImg $imageBorder $images

      imgW=$(identify -format "%w" $tmpImg)

      # There is room for this image
      if [ $imgW -le $freeW ]
      then
        freeW=$((${freeW}-${imgW}))
      # Montage all the images in a row and go to the next row
      else
        montage \
          $tmpDir/image_${row}_*.png \
          -tile x1 \
          -geometry +0+0 \
          -gravity north \
          -background white \
          $tmpRowImg 
        break
      fi
    done # loop cols

    imgH=$(identify -format "%h" $tmpRowImg)

    # There is room for this row
    if [ $imgH -le $freeH ]
    then
      freeH=$((${freeH}-${imgH}))
    # Put all the rows together and exit
    else
      fileRows=$(ls -1 $tmpDir/image_*.png|grep 'image_[0-9]*.png')
      trace "Building the army with the rows $fileRows ..."
      montage \
        $fileRows \
        -tile 1x \
        -geometry +0+0 \
        -gravity north \
        -background white \
        $file
      break
    fi
  done
  convert -border $borderCanvas -bordercolor white $file $file
# Generate a serie of rows and put together
else
  # We can have several fromnt/back images and we have to mix them. 
  total=0
  
  # Copy all the fronts to a folder so we can manipulate them
  rebuildDir "$tmpDir/front"
  totFront=0
  resizes=""
  for f in $(ls -1 $patternFront|sort)
  do
    resize=$(($hInPx + ($RANDOM % 30)))
    resizes="${resizes}${resize} "
  
    echo "Resize front $totFront : $resize"
    convert $f -resize "x${resize}" $tmpDir/front/$totFront.png
    
    totFront=$(($totFront+1))
  done
  
  # Copy all the backs to a folder so we can manipulate them
  rebuildDir "$tmpDir/back"
  totBack=0
  echo "resizes : $resizes"
  for f in $(ls -1 $patternBack|sort)
  do
    resize=$(echo ${resizes}|cut -d ' ' -f $(($totBack+1)),$(($totBack+1)))
  
    echo "Resize back $totBack : $resize"
    convert $f -resize "x${resize}" $tmpDir/back/$totBack.png
    
    totBack=$(($totBack+1))
  done
  
  # TODO : verify both numbers are the same
  total=$totFront
  
  # Resize to the same height
  maxH=$(getMaxH $tmpDir/back/* $tmpDir/front/*)
  
  # Resize the fronts
  for f in $(ls -1 $tmpDir/front/*)
  do
    echo "Converting $f ..."
    w=$(identify -format "%w" $f)
    convert -size ${w}x${maxH} xc:white $f -gravity south -composite $f
  done
  
  # Resize the backs
  for f in $(ls -1 $tmpDir/back/*)
  do
    echo "Converting $f ..."
    w=$(identify -format "%w" $f)
    convert -size ${w}x${maxH} xc:white $f -gravity north -composite $f
  done
  
  # Generate the rows
  for(( row=0; row<3; row++))
  do
    trace "Generating Row $row ..."
    tmpFile=$tmpDir/row_${row}.png
    genRow $total 8 $tmpFile
  done
  
  # Generate the army
  genArmy $file $tmpDir/row_*.png
fi
