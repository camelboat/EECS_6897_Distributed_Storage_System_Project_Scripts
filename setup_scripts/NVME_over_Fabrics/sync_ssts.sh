#!/bin/bash

inotifywait -m /path -e create -e moved_to |
  while read path action file; do
    echo "${path} ${action} ${file}"
  done
