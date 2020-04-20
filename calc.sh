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
valueInInReal=1
valueInCmReal=1

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Calculator inches / cm / pixels

SYNOPSIS
       `basename $0` [-s] [-S integer] [-r integer] [-i | -p | -c | -I | -C]  value

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

      -I
              Value is in inches (real)

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
while getopts "hsd:S:r:piIcC" opt
do
  case $opt in
    h)
      help
      exit 0
      ;;
    s) silent=1 ;;
    S) scale=$OPTARG ;;
    r) resolution=$OPTARG ;;
    p) 
      valueInPx=1 
      valueInIn=0 
      valueInInReal=0 
      valueInCm=0 
      valueInCmReal=0 
    ;;
    i) 
      valueInPx=0 
      valueInIn=1
      valueInInReal=0 
      valueInCm=0 
      valueInCmReal=0 
    ;;
    I) 
      valueInPx=0 
      valueInIn=0 
      valueInInReal=1
      valueInCm=0
      valueInCmReal=0
    ;;
    c) 
      valueInPx=0 
      valueInIn=0 
      valueInInReal=0 
      valueInCm=1 
      valueInCmReal=0 
    ;;
    C) 
      valueInPx=0 
      valueInIn=0 
      valueInInReal=0 
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
Inches (real)        : $(screen2Real ${value} ${scale})
----------------------------------------
EOD
fi

if [ $valueInPx -eq 1 ]
then
  cat<<EOD
----------------------------------------
Pixels              : ${value}

Inches (screen)     : $(px2In ${value} ${resolution})
Inches (real)       : $(screen2Real $(px2In ${value} ${resolution}) ${scale})
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
Inches (real)        : $(screen2Real $(cm2In ${value}) ${scale})
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
Inches (screen)      : $(real2Screen $(cm2In ${value}) ${scale})
Inches (real)        : $(cm2In ${value})
Pixels               : $(in2Px $(real2Screen $(cm2In ${value}) ${scale}) ${resolution})
----------------------------------------
EOD
fi

if [ $valueInInReal -eq 1 ]
then
  cat<<EOD
----------------------------------------
Inches (real)        : $value

Centimeters (screen) : $(real2Screen $(in2Cm ${value}) ${scale})
Centimeters (real)   : $(in2Cm ${value})
Inches (screen)      : $(real2Screen ${value} ${scale})
Pixels               : $(in2Px $(cm2In $(real2Screen ${value} ${scale})) ${resolution})
----------------------------------------
EOD
fi
rm ${tmpFile}* 2>/dev/null

