#!/bin/bash

# =================================================
# Gloabl variables
# =================================================
INCHES_TO_CM=2.54

# =================================================
# Gloabl functions
# =================================================
function trace() {
  [ $silent -eq 0 ] && echo $* >&2
}

function rebuildDir() {
  local dir=$1

  [ -d $dir ] && rm -fR $dir
  [ ! -d $dir ] && mkdir -p $dir
}

function in2Cm () {
  local _value=$1

  echo "${_value}*$INCHES_TO_CM"|bc -l
}

function cm2In () {
  local _value=$1

  echo "${_value}/$INCHES_TO_CM"|bc -l
}

function real2Screen () {
  local _value=$1
  local _scale=$2

  echo "${_value}/${_scale}"|bc -l
}

function screen2Real () {
  local _value=$1
  local _scale=$2

  echo "${_value}*${_scale}"|bc -l
}

function in2Px () {
  local _value=$1
  local _resolution=$2

  echo "${_value}*${_resolution}"|bc -l
}

function px2In () {
  local _value=$1
  local _resolution=$2

  echo "${_value}/${_resolution}"|bc -l
}
