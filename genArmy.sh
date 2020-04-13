#!/bin/bash
#convert $fileFront -background white -alpha remove -alpha off $tmpDir/front.png
#convert $fileBack  -background white -alpha remove -alpha off $tmpDir/back.png

# =================================================
# Variables
# =================================================
silent=0
#tmpFile=/tmp/$(basename $0).$$
tmpFile=/tmp/$(basename $0)
outFile="army.png"
images=""  # List of all images used as input
isImgFull=0
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
borderCanvas=10
# Border in the image (px)
imageBorder=0

cellWithIn=6
cellNumRows=2

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Generates an army using a back and front images 

SYNOPSIS
       `basename $0` [-s] [-F] [-o file] [-r number] [-w inches] images

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

       -r number
              Number of rows in each group (def: $cellNumRows)

       -w inches
              Width (in inches) for every cell (def: $cellWithIn)
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $*
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
  local img=$1
  local imageBorder=$2
  shift 2
  local images=$*
  
  getRandomImage $img $imageBorder $images
}

# Build a rectangle with a group of elements
# @width : with in Inches that form the bases
# @numRows : number of rows (we prefer this method that specify inches)
# This method is used working with front / back separated; I have tried to be "agnotstic"
# if the images are complete or not but it makes too difficult and probably has no sense
function getCellGroup() {
  local _outImg=$1
  local _imageBorder=$2
  local _width=$3
  local _numRows=$4
  shift 4
  local _images=$*
  
  local _tmpFile=${tmpFile}.getCellGroup
  rm ${_tmpFile}* 2>/dev/null

  # Build one by one all the rows an then put them together
  rm ${_tmpFile}.row.*.png 2>/dev/null
  local _row=0
  for ((_row=0;_row<${_numRows};_row++))
  do
    # Ok, the plan is:
    # - Create row with back
    # - Create row with front
    # - Put them together and create the row
    # When building the front/back we align them and leave space to the highest

    local _freeW=$((${_width}*${resolution}))

    rm ${_tmpFile}.col.*.png 2>/dev/null
    local _col=0
    for ((_col=0; ;_col++))
    do
      local _imageFront=$( getRandomValue $_images )
      local _imageBack=$( echo  $_imageFront|sed -e 's/-front/-back/' )
      local _resize=$( getRandomResize )

      # Generate the single image for this col (front and back)
      convert \( -size ${_imageBorder}x xc:red \)     \
              \( -resize ${_resize}% ${_imageFront} \)  \
              \( -size ${_imageBorder}x xc:red \)     \
              +append                                   \
              ${_tmpFile}.front.${_col}.png 

      convert \( -size ${_imageBorder}x xc:red \)     \
              \( -resize ${_resize}% ${_imageBack} \)   \
              \( -size ${_imageBorder}x xc:red \)     \
              +append                                   \
              ${_tmpFile}.back.${_col}.png 

      trace "Col : ${_col}, frontW : $(identify -format "%w" ${_tmpFile}.front.${_col}.png), backW : $( identify -format "%w" ${_tmpFile}.back.${_col}.png )"

      local _imgW=$(identify -format "%w" ${_tmpFile}.front.${_col}.png )

      # There is room for this image
      if [ ${_imgW} -le ${_freeW} ]
      then
        _freeW=$((${_freeW}-${_imgW}))
      # Remove the last image created because there is no room
      else
        rm ${_tmpFile}.back.${_col}.png 
        rm ${_tmpFile}.front.${_col}.png 
      fi

      # Check again because if the block we have just made is bigger than
      # the remainign probably the next block we will have the same dimensions
      # and it has no sense to continue
      if [ ${_imgW} -gt ${_freeW} ]
      then
        # Ok, I have try to make it in a sigle command but I do not 
        # find the way to concat all the images (eg.back) in a image stack \( ... \)
        # so,,,
        convert  ${_tmpFile}.back.*.png  -gravity north +append ${_tmpFile}.rowBack.${_row}.png
        convert  ${_tmpFile}.front.*.png -gravity south +append ${_tmpFile}.rowFront.${_row}.png

        # Now we should create a row that should be: basis + back + front + basis but
        # becauase every back/front have different sizes let's do it at the end when we
        # get the max values
        break
      fi
    done # loop cols
  done # loop rows

  # Create the basis and build the rows
  local _maxW=$(getMaxW ${_tmpFile}.rowBack.*.png)
  local _maxH=$(getMaxH ${_tmpFile}.rowBack.*.png)
  local _file=""
  for ((_row=0;_row<${_numRows};_row++))
  do
    trace "Row : ${_row}, frontW : $(identify -format "%w" ${_tmpFile}.rowFront.${_row}.png), backW : $( identify -format "%w" ${_tmpFile}.rowBack.${_row}.png )"
    montage \
      \( -size "${_maxW}x$((${_maxH}/4))" xc:"#4d2600"  \) \
      ${_tmpFile}.rowBack.${_row}.png \
      \( -size "${_maxW}x2" xc:gray \) \
      ${_tmpFile}.rowFront.${_row}.png \
      \( -size "${_maxW}x$((${_maxH}/4))" xc:"#4d2600"  \) \
      -tile 1x \
      -geometry +0+0 \
      -background white \
     ${_tmpFile}.row.${_row}.png 
  done

  # Now just put all the rows together
  montage \
    ${_tmpFile}.row.*.png \
    -tile 1x \
    -geometry +0+00 \
    -gravity north \
    -background white \
    ${_outImg}

  # Clean up
  rm ${_tmpFile}* 2>/dev/null

  #echo ${_outImg}
}

# =================================================
# Arguments
# =================================================
while getopts "hso:Fr:w:" opt
do
  case $opt in
    h)
      help
      exit 0
      ;;
    s) silent=1 ;;
    o) outFile=$OPTARG ;;
    F) isImgFull=1 ;;
    r) cellNumRows=$OPTARG ;;
    w) cellWithIn=$OPTARG ;;
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

# Now generate random images and add them
# TODO : sure this can be done with less temporary files but ...
freeH=$(roundValue "${canvasH}-2*${borderCanvas}")
rm $tmpFile.row.${row}.png 2>/dev/null
for((row=0; ; row++))
do
  tmpImgRow=$tmpFile.row.${row}.png
  trace "Building row $row (free : $freeH) ..."

  freeW=$(roundValue "${canvasW}-2*${borderCanvas}")
  rm $tmpFile.col.*.png 2>/dev/null
  for((col=0; ; col++))
  do
    tmpImgCol=$tmpFile.col.${col}.png
    getCellGroup $tmpImgCol $imageBorder $cellWithIn $cellNumRows $images
    convert -border 10 -bordercolor white $tmpImgCol $tmpImgCol

    imgW=$(identify -format "%w" $tmpImgCol)

    # There is room for this image
    trace "cellW : $imgW, freeW : $freeW"
    if [ $imgW  -le  $freeW  ]
    then
      freeW=$((${freeW}-${imgW}))
    # Remove what we have done
    else
      rm $tmpImgCol
    fi

    if [ $imgW  -gt  $freeW  ]
    then
      break
    fi
  done # loop cols

  # Make the row with all the cells
  trace "Make the row $tmpImgRow with $tmpFile.col.*.png ..."

  montage \
    $tmpFile.col.*.png \
    -tile x1 \
    -geometry +0+0 \
    -gravity north \
    -background white \
    $tmpImgRow

  imgH=$(identify -format "%h" $tmpImgRow)

  trace "imgH : $imgH, freeH : $freeH"
  # There is room for this row
  if [ $imgH -le $freeH ]
  then
    freeH=$((${freeH}-${imgH}))
  # Put all the rows together and exit
  else
    rm $tmpImgRow
  fi

  if [ $imgH -gt $freeH ]
  then
    break
  fi
done

trace "Building the army with the rows ..."
montage \
  $tmpFile.row.*.png \
  -tile 1x \
  -geometry +0+0 \
  -gravity north \
  -background white \
  $outFile
convert -border $borderCanvas -bordercolor white $outFile $outFile

#rm ${tmpFile}* 2>/dev/null
