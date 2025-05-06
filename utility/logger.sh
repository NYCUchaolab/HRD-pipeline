#!/bin/sh

log() {
  local level=$1
  shift
  if [[ $VERBOSE -ge $level ]]; then
    echo -e "$@"
  fi
}