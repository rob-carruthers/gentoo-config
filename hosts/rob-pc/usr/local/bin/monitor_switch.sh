#!/usr/bin/env bash

if [ ! -f /home/rob/noswitch ] ; then
  if [[ "$1" == "add" ]]; then
    ddcutil setvcp 60 x0f
  elif [[ "$1" == "remove" ]]; then
    ddcutil setvcp 60 x11
  fi
fi

