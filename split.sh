#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
image=""
inDir="/tmp/$(basename $0).$$.in"
workDir="/tmp/$(basename $0).$$.work"
tmpDir="/tmp/$(basename $0).$$.tmp"
dstDir=""
# If split done once
doSplitOnce=0
splitOnceMode="rows"

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Split an image in boxes containing the composed images, removing blanks

SYNOPSIS
       `basename $0` [-s] -i file -d dir [-S] [-m rows|cols]

DESCRIPTION
       Split an image in boxes containing the composed images, removing blanks

       -i file
              Image

       -d dir
              Folder where the images are stored

       -S
              Split is executed once. By default done until all white is removed

       -m R|C
              If the split is executed once, this is done in Rows or Columns (def: $splitOnceMode)

EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $*
}

function rebuildDir() {
  local dir=$1

  [ -d $dir ] && rm -fR $dir
  [ ! -d $dir ] && mkdir -p $dir
}

# Given an image return a string containing the characters W and C 
# (eg. WWWCCCCWWCWWC) indicating (depending on mode) if the 
# ROWS/COLS are ALL White (W) or there are some non-white (C)
# This is useful for detecting "empty" ROWS/COLS and remove them (margins) 
# ir to know where we can split the image
function getImageWC() {
  local image=$1
  local mode=$2

  local str=""
  local tmpFile=$tmpDir/$$

  local tot=0
  case $mode in
    # Colapse to one column
    rows) 
      tot=$(identify -format "%h" $image) 
      convert ${image} -resize "1x${tot}!" $tmpFile
      ;;
    # Colapse to one row
    *)    
      tot=$(identify -format "%w" $image) 
      convert ${image} -resize "${tot}x1!" $tmpFile
      ;;
  esac

  # Loop through all rows/cols
  local ind=0
  for ((ind=0; ind<tot; ind++))
  do
     local num=0
     case $mode in
       rows) num=$(convert $tmpFile[1x1+0+${ind}] txt: | grep -v enumeration | grep -c '#FFFFFF') ;;
       *)    num=$(convert $tmpFile[1x1+${ind}+0] txt: | grep -v enumeration | grep -c '#FFFFFF') ;;
     esac

     if [ $num -eq 1 ]
     then
       str="${str}W"
     else
       str="${str}C"
     fi
  done
   
  echo "$str"
}

# Given a string with W/C (eg. WWWCCCCWWCCWW) return the values of the limits at both sides with W;
# e.g "3 2" (there are 3 Whites in the beginning and 2 W at the end)
function getHeadTot() {
  local str=$1

  local frg=$(echo $str|sed -e 's/\(^W*\).*/\1/')

  echo ${#frg}
}

function getTailTot() {
  local str=$1

  local frg=$(echo $str|rev|sed -e 's/\(^W*\).*/\1/')

  echo ${#frg}
}

# Given an image, remove the empty blanks top/bottom/left/right
function removeMargins() {
  local image=$1
  local dstImage=$2

  local rows=$(getImageWC $image "rows")
  local cols=$(getImageWC $image "cols")

  # find the limits top, bottom, left, right
  local top=$(getHeadTot $rows)
  local bottom=$(getTailTot $rows)
  local left=$(getHeadTot $cols)
  local right=$(getTailTot $cols)

  convert $image -crop +${left}+${top} -crop -${right}-${bottom} $dstImage
}

# Given an image, split in rows/columns and keep the non-white portions in dstDir
function splitImg() {
  local image=$1
  local mode=$2
  local dstDir=$3

  local imgName="$dstDir/$(basename $image|sed -e 's/\..*//')"
  local imgExt=$(basename $image|sed -e 's/.*\.//')

  local str=""
  case $mode in
    rows) str=$(getImageWC $image "rows") ;;
    *)    str=$(getImageWC $image "cols") ;;
  esac

  # Make a copy or the image because we're goint to modify it
  local myImg="$tmpDir/$(basename $image)"
  cp $image $myImg
  echo "myImg : $myImg"

  local index=0
  while [ ${#str} -ne 0 ]
  do
    local ch=${str:0:1} 
    local frg=$(echo $str|sed -e "s/\(^${ch}*\).*/\1/")
    str=$(echo $str|sed -e "s/^${ch}*//")
    #index=$(($index+1)) 

    # echo "ch:$ch"
    echo "frg:$frg"
    # echo "str:$str"
    # Non white strip, keep it
    if [ "$ch" == "C" ]
    then
      local file=${imgName}-${index}.${imgExt}
      case $mode in
        rows) convert $myImg -crop x${#frg}+0+0 $file ;;
        *)    convert $myImg -crop ${#frg}x+0+0 $file ;;
      esac
      index=$(($index+1)) 
    fi

    # Remove block from the original image
    case $mode in
      rows) convert $myImg -chop 0x${#frg}+0+0 $myImg ;;
      *)    convert $myImg -chop ${#frg}x0+0+0 $myImg ;;
    esac
  done
}

# =================================================
# Arguments
# =================================================
while getopts "hsd:i:Sm:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    i) image=$OPTARG ;;
    d) dstDir=$OPTARG ;;
    S) doSplitOnce=1 ;;
    m) splitOnceMode=$OPTARG ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# --- Check Arguments
errors=""

if [[ -z "$image" ]]
then
  errors="${errors}An image must be specified. "
fi

if [[ -z "$dstDir" ]]
then
  errors="${errors}A folder must be specified. "
fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================

rebuildDir $inDir
rebuildDir $workDir
rebuildDir $tmpDir
rebuildDir $dstDir

if [ $doSplitOnce -eq 1 ]
then
  splitImg $image $splitOnceMode $dstDir
else
  cat<<EOD
in : $inDir
work : $workDir
tmp : $tmpDir
dst : $dstDir
EOD

  # The loop consist in 5 phases for every image
  # 1) Remove margins
  # 2) Split Rows
  #    - Changes : for every image repeat loop
  #    - No Chages:
  # 3) Split in Cols
  #    - Changes : for every image repeat loop
  #    - No Chages: Final image, ypu can keep it
  cp $image $inDir
  
  # Loop over all the images in $inDir
  files=$(ls -1 $inDir/*)
  step=0
  rebuildDir tmp
  while [ ! -z "$files" ]
  do
    # TMP
    mkdir tmp/$step
    cp -r $inDir    tmp/$step/IN 
    cp -r $workDir  tmp/$step/WORK
    cp -r $dstDir   tmp/$step/OUT
    step=$(($step+1))
    # TMP
  
    for f in $files
    do
      echo "Processing $f..."
  
      echo "Splitting in ROWS ..."
  
      # Split in rows
      rm $workDir/* 2>/dev/null
      splitImg $f "rows" $workDir
    
      # Check if has generates new images
      # For a strane reason diff says there are changes when not ..
      changed=1
    
      if [[ $(ls -1 $workDir/*|wc -l) -eq 1 && "$(identify -format "%wx%h" $f)" == "$(identify -format "%wx%h" $workDir/*)" ]]
      then
        changed=0
      fi
    
      if [ $changed -eq 1 ]
      then
        echo "[ROWS] : Generated $(ls -1 $workDir/*)"
      # No Changes? Try Split H
      else
        echo "Split in COLS ..."
  
        rm $workDir/*
        splitImg $f "cols" $workDir
    
        # Check if the image has changed
        changed=1
    
        if [[ $(ls -1 $workDir/*|wc -l) -eq 1 && "$(identify -format "%wx%h" $f)" == "$(identify -format "%wx%h" $workDir/*)" ]]
        then
          changed=0
        fi
  
        # No changes? Keep if
        if [ $changed -eq 1 ]
        then
          echo "[COLS] : Generated $(ls -1 $workDir/*)"
          echo "Generated new images split in columns!"
        else
          echo "Keeping image $workDir/*"
          mv $workDir/* $dstDir
        fi 
      fi
  
      # Copy the files , we must process them
      cp $workDir/* $inDir
      # Remove the file
      rm $f
    done # for files in inDir
  
    files=$(ls -1 $inDir/*)
  done
fi # doSplitOnce
