#!/bin/bash

# =================================================
# Gloabl functions
# =================================================
function trace() {
  [ $silent -eq 0 ] && echo $*
}

function rebuildDir() {
  local dir=$1

  [ -d $dir ] && rm -fR $dir
  [ ! -d $dir ] && mkdir -p $dir
}
