#!/bin/bash


# =================================================
# Variables
# =================================================
silent=0
tmpFile=/tmp/$(basename $0).$$
resolution=300 # 300 ppi
scale=72       # Mean 1/72
value=""
valueInIn=1
valueInPx=1
valueInCm=1
valueInCmReal=1

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Calculator inches / cm / pixels

SYNOPSIS
       `basename $0` [-s] [-S integer] [-r integer] [-i | -p | -c | -C]  value

DESCRIPTION
       Given <value> that is a value represented in inches, pixels or centimeters, will transform
       in the other units applying <resolution> and <scale>.
       If the type is not specified, it will transform to all of them.

       -s
              Silent mode

       -S integer
              Scale in the form 1/<scale> (def: ${scale})

       -r integer
              Resolution in ppi (def: $resolution)

      -p 
              Value is in pixels

      -i 
              Value is in inches (screen)

      -c 
              Value is in centimeters (screen)

      -C
              Value is in centimeters (real)

EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $*
}

# =================================================
# Arguments
# =================================================
while getopts "hsd:S:r:ipcC" opt
do
  case $opt in
    h)
      help
      exit 0
      ;;
    s) silent=1 ;;
    S) scale=$OPTARG ;;
    r) resolution=$OPTARG ;;
    i) 
      valueInIn=1
      valueInPx=0 
      valueInCm=0 
      valueInCmReal=0 
    ;;
    p) 
      valueInIn=0 
      valueInPx=1 
      valueInCm=0 
      valueInCmReal=0 
    ;;
    c) 
      valueInIn=0 
      valueInPx=0 
      valueInCm=1 
      valueInCmReal=0 
    ;;
    C) 
      valueInIn=0 
      valueInPx=0 
      valueInCm=0
      valueInCmReal=1 
    ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $(( OPTIND - 1 ))
value=$1

# --- Check Arguments
errors=""

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================
rm ${tmpFile}* 2>/dev/null

. ./funcs.sh

if [ $valueInIn -eq 1 ]
then
  cat<<EOD
----------------------------------------
Inches (screen)      : $value

Pixels               : $(in2Px ${value} ${resolution})
Centimeters (screen) : $(in2Cm ${value})
Centimeters (real)   : $(screen2Real $(in2Cm $value) ${scale})
----------------------------------------
EOD
fi

if [ $valueInPx -eq 1 ]
then
  cat<<EOD
----------------------------------------
Pixels              : ${value}

Inches (screen)     : $(px2In ${value} ${resolution})
Centimeters (scren) : $(in2Cm $(px2In ${value} ${resolution}))
Centimeters (real)  : $(screen2Real $(in2Cm $(px2In ${value} ${resolution})) ${scale})
----------------------------------------
EOD
fi

if [ $valueInCm -eq 1 ]
then
  cat<<EOD
----------------------------------------
Centimeters (screen) : $value

Pixels               : $(in2Px $(cm2In ${value}) ${resolution})
Inches (screen)      : $(cm2In ${value})
Centimeters (real)   : $(screen2Real ${value} ${scale})
----------------------------------------
EOD
fi

if [ $valueInCmReal -eq 1 ]
then
  cat<<EOD
----------------------------------------
Centimeters (real)    : $value

Centimeters (screen) : $(real2Screen ${value} ${scale})
Inches (screen)      : $(cm2In $(real2Screen ${value} ${scale}))
Pixels               : $(in2Px $(cm2In $(real2Screen ${value} ${scale})) ${resolution})
----------------------------------------
EOD
fi

rm ${tmpFile}* 2>/dev/null

