#!/bin/bash
#convert $fileFront -background white -alpha remove -alpha off $tmpDir/front.png
#convert $fileBack  -background white -alpha remove -alpha off $tmpDir/back.png

# =================================================
# Variables
# =================================================
#tmpFile=/tmp/$(basename $0).$$
tmpFile=/tmp/$(basename $0)

silent=0
outFile="army.png"
images=""  # List of all images used as input
isImgFull=0

# Reize allowed im the images (in %)
resizeLessPerc=100
resizeMorePerc=100

# TODO : this should be a parameter but let's suppose the final canvas is 
# an A4 8.27 × 11.69 inches with resolution 300 ppi (we leave some borders)
resolution=300
canvasW=$(echo "8.27*$resolution"|bc -l)
canvasH=$(echo "11.69*$resolution"|bc -l)
# In pixels, we want to leave 1 cm more or less that with a resolution 300ppi
# than means 100px
borderCanvas=0

# Border in the image (px)
imageBorder=0

# Separation (in pixels) between columns and rows
sepColInPx=80
sepRowInPx=80

# Color used in the separation (it corresponds to the terrain)
sepColColor="#4d2600"  # Brown
sepRowColor="white"  # Brown

# Border in the North, South, East and Wet of every cell (in pixels)
borderN=0
borderS=0
borderE=0
borderW=0

# Color in the border
borderColor=white

cellNumRows=2
cellNumCols=2

# Total cells generated; if not specified so many as possible
totCells=""

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Generates an army using a back and front images 

SYNOPSIS
       `basename $0` [-s] [-F] [-o file] [-t number]
          [-c number] [-C pixel] [-L color] 
          [-r number] [-R pixel] [-O color]
          [-N pixel] [-S pixel] [-E pixel] [-W pixel] [-B color] 
          images

DESCRIPTION
       Generates an army in two modes:
       + If images are "not full" : put them together to make the figures with back and front, glue together 
         to make rows and glue rows together to make the army
       + If images "are full" : get random figures and fill the entire page with it

       -F
              Images provided are "full" (with front/back joined). Otherwise the images are only the
              front and the back are found changing '-front' => '-back'

       -o file
              Output file with the image containing the army (def: $outFile)

       -t number
              Number of cells generated. If not specified, maximum number of cells will be generated.

       -c number
              Number of columns in each group (def: $cellNumCols)

       -C pixel
              Separation in pixel between columns (def: $sepColInPx)

       -L color
              String represents the color used in the space between coLumns (def: $sepColColor)

       -r number
              Number of rows in each group (def: $cellNumRows)

       -R pixel
              Separation in pixel between rows (def: $sepRowInPx)

       -O color
              String represents the color used in the space between rOws (def: $sepRowColor)

       -N, -S, -E, -W  pixel
              Border in the North, South, East, West in every cell (def: 0)

       -B color
              Color used in the border

       #-w inches
       #       Width (in inches) for every cell (def: $cellWithIn)
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $* >&2
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

# Join cols to make a row
# - All the same height
# - Leave an space in between
# NOTE : this function CHANGE the images
function joinCols() {
  local _spaceInPx=$1
  local _spaceColor=$2
  local _gravity=$3
  local _outImg=$4
  shift 4
  local _images=$*
 
  local _maxH=$(getMaxH ${_images})

  # Add a margin at the left of every image (not in the first)
  local _img=""
  local _tmpSep=0
  for _img in ${_images}
  do
    #trace "sep : ${_tmpSep}, maxH : ${_maxH}"
    convert \
      \( -size ${_tmpSep}x${_maxH} xc:${_spaceColor} \) \
      -gravity ${_gravity} \
      ${_img} \
      +append \
      ${_img}

    _tmpSep=${_spaceInPx}
  done

  # Now put all the images together in a row
  convert  ${_images} +append ${_outImg}
}
# Build a row of images:
# - All the same height
# - Leave an space in between
# NOTE : this function CHANGE the images
function joinRows() {
  local _spaceInPx=$1
  local _spaceColor=$2
  local _gravity=$3
  local _outImg=$4
  shift 4
  local _images=$*
 
  local _maxW=$(getMaxW ${_images})

  # Add a margin at the top of every image (not in the first)
  local _img=""
  local _tmpSep=0
  for _img in ${_images}
  do
    # trace "sep : ${_tmpSep}, maxH : ${_maxH}"
    convert \
      \( -size ${_maxW}x${_tmpSep} xc:${_spaceColor} \) \
      ${_img} \
      -append \
      ${_img}

    _tmpSep=${_spaceInPx}
  done

  # Now put all the images together in a row
  convert  ${_images} -append ${_outImg}
}
 

function getRandomValue() {
  local _images=$*
 
  # Pick a random image
  local _total=$(echo $_images|wc -w)
  local _ind=$(( $RANDOM % ${_total} ))

  echo $_images|cut -d ' ' -f $(($_ind+1)),$(($_ind+1)) 
}

# Random resize between [resizeLessPerc, resizeMorePerc]
function getRandomResize() {
  if [ $resizeMorePerc -eq $resizeLessPerc ]
  then
    echo $resizeMorePerc
  else
    echo $(( ($RANDOM % ($resizeMorePerc-$resizeLessPerc))+$resizeLessPerc ))
  fi
}

function getRandomImage() {
  local _file=$1
  local _border=$2
  shift 2
  local _images=$*

  # Pick a random image
  local _image=$( getRandomValue $_images )

  # Random resize between [resizeLessPerc, resizeMorePerc]
  local _resize=$( getRandomResize )

  # Final image = resize + border around
  if [ $isImgFull -eq 1 ]
  then
    convert -resize ${_resize}% -border ${_border} -bordercolor white ${_image} ${_file}
  # It is the front image : resize and add some borders in the sides (the top will see when 
  # we get all the images and align them
  else
    convert \( -size ${_border}x xc:white \)     \
            \( -resize  ${_resize}% ${_image} \) \
            \( -size ${_border}x xc:white \)     \
            +append \
            ${_file}
  fi
}

# Build a "cell" that depending on the configuration can be
# composed by just one image or a group of them
function getCell() {
  local _img=$1
  local _imageBorder=$2
  shift 2
  local _images=$*
  
  getRandomImage ${_img} ${_imageBorder} ${_images}
}

# Build a rectangle with a group of elements
# This method is used working with front / back separated; I have tried to be "agnotstic"
# if the images are complete or not but it makes too difficult and probably has no sense
function getCellGroup() {
  local _outImg=$1
  local _imageBorder=$2
  local _numCols=$3
  local _numRows=$4
  local _sepColsInPx=$5
  local _sepRowsInPx=$6
  shift 6
  local _images=$*
  
  local _tmpFile=${tmpFile}.getCellGroup
  rm ${_tmpFile}* 2>/dev/null

  # Build one by one all the rows an then at the end put them together
  rm ${_tmpFile}.row.*.png 2>/dev/null
  local _row=0
  for ((_row=0;_row<${_numRows};_row++))
  do
    # Ok, the plan is:
    # - Create row with back
    # - Create row with front
    # - Put them together and create the row
    # When building the front/back we align them and leave space to the highest

    rm ${_tmpFile}.col.*.png 2>/dev/null

    # Create the 'cols' with the backs and the fronts
    local _col=0
    for ((_col=0; _col<${_numCols} ;_col++))
    do
      local _imageFront=$( getRandomValue $_images )
      local _imageBack=$( echo  $_imageFront|sed -e 's/-front/-back/' )
      local _resize=$( getRandomResize )

      # Generate the single image for this col (front and back)
      convert -resize ${_resize}% ${_imageFront} ${_tmpFile}.front.${_col}.png
      convert -resize ${_resize}% ${_imageBack}  ${_tmpFile}.back.${_col}.png
    done # loop cols

    # Put all the columns together and create the row with the backs and the row with the fronts
    joinCols ${sepColInPx} ${sepColColor} north ${_tmpFile}.rowBack.${_row}.png  ${_tmpFile}.back.*.png 
    joinCols ${sepColInPx} ${sepColColor} south ${_tmpFile}.rowFront.${_row}.png ${_tmpFile}.front.*.png 

    # Put back and front together to create a row
    joinRows 2 gray center ${_tmpFile}.row.${_row}.png ${_tmpFile}.rowBack.${_row}.png ${_tmpFile}.rowFront.${_row}.png
  done # loop rows

  # Now just put all the rows together
  joinRows ${sepRowInPx} ${sepRowColor} center ${_outImg} ${_tmpFile}.row.*.png 

  # Add border (if any) in N, S, E, W
  local _outImgW=$(identify -format "%w" ${_outImg})
  local _outImgH=$(identify -format "%h" ${_outImg})

  [ $borderN -ne 0 ] && convert \( -size ${_outImgW}x${borderN} xc:${borderColor} \) ${_outImg} -append  ${_outImg}
  [ $borderS -ne 0 ] && convert ${_outImg} \( -size ${_outImgW}x${borderS} xc:${borderColor} \) -append  ${_outImg}
  [ $borderE -ne 0 ] && convert ${_outImg} \( -size ${borderE}x${_outImgH} xc:${borderColor} \) +append  ${_outImg}
  [ $borderW -ne 0 ] && convert \( -size ${borderW}x${_outImgH} xc:${borderColor} \) ${_outImg} +append  ${_outImg}
 
  # Final border around the cell
  # TODO : parameter
  convert -border 10 -bordercolor white ${_outImg} ${_outImg}

  # Clean up
  rm ${_tmpFile}* 2>/dev/null
}

# =================================================
# Arguments
# =================================================
while getopts "hsFo:t:c:r:C:R:L:O:N:S:E:W:B:" opt
do
  case $opt in
    h)
      help
      exit 0
      ;;
    s) silent=1 ;;
    o) outFile=$OPTARG ;;
    t) totCells=$OPTARG ;;
    F) isImgFull=1 ;;
    c) cellNumCols=$OPTARG ;;
    r) cellNumRows=$OPTARG ;;
    C) sepColInPx=$OPTARG ;;
    R) sepRowInPx=$OPTARG ;;
    L) sepColColor=$OPTARG ;;
    O) sepRowColor=$OPTARG ;;
    N) borderN=$OPTARG ;;
    S) borderS=$OPTARG ;;
    E) borderE=$OPTARG ;;
    W) borderW=$OPTARG ;;
    B) borderColor=$OPTARG ;;
    #w) cellWithIn=$OPTARG ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $(( OPTIND - 1 ))
images=$*

# --- Check Arguments
errors=""

if [[ -z "$outFile" ]]
then
  errors="${errors}A destination file  must be specified. "
fi

if [[ $(echo $images|wc -w) -eq 0 ]]
then
  errors="${errors}You must specify input images. "
else
  for f in $images
  do
    [ ! -f $f ] && errors="${errors}File $f does not exit. "
  done
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

source ./funcs.sh

# Generate random "cell of images" using the images provided and put "as much as possible" in a canvas
# Depending on the parameters the cell can be:
# - Individual figure
# - Group of them

# Create "rows" until we have no more space
freeH=$(roundValue "${canvasH}-2*${borderCanvas}")
rm $tmpFile.row.${row}.png 2>/dev/null
numCells=0
for((row=0; ; row++))
do
  [[ ! -z "${totCells}" && ${numCells} -ge ${totCells} ]] && break

  tmpImgRow=$tmpFile.row.${row}.png
  trace "Building row $row (free : $freeH) ..."

  # Create "cols" until we have no more space
  freeW=$(roundValue "${canvasW}-2*${borderCanvas}")
  rm $tmpFile.col.*.png 2>/dev/null
  for((col=0; ; col++))
  do
    [[ ! -z "${totCells}" && ${numCells} -ge ${totCells} ]] && break
    trace "Generating Cell #${numCells} of ${totCells} ..."
    numCells=$(($numCells+1))

    tmpImgCol=$tmpFile.col.${col}.png
    getCellGroup $tmpImgCol $imageBorder $cellNumCols $cellNumRows $sepColInPx $sepRowInPx $images

    imgW=$(identify -format "%w" $tmpImgCol)

    # There is room for this image
    #trace "cellW : $imgW, freeW : $freeW"
    if [ $imgW  -le  $freeW  ]
    then
      freeW=$((${freeW}-${imgW}))
    # Remove what we have done
    else
      rm $tmpImgCol
      break
    fi
  done # loop cols

  # Make the row with all the cells
  trace "Make the row $tmpImgRow with $tmpFile.col.*.png ..."
  joinCols 5 white north $tmpImgRow $tmpFile.col.*.png 

  imgH=$(identify -format "%h" $tmpImgRow)

  #trace "imgH : $imgH, freeH : $freeH"
  # There is room for this row
  if [ $imgH -le $freeH ]
  then
    freeH=$((${freeH}-${imgH}))
  # Put all the rows together and exit
  else
    rm $tmpImgRow
    break
  fi
done

trace "Put all the rows together ..."
joinRows 5 white center $outFile $tmpFile.row.*.png 
#convert -border $borderCanvas -bordercolor white $outFile $outFile

rm ${tmpFile}* 2>/dev/null
