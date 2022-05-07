#!/bin/bash
set -x

# kill existing dstat program
kill $(ps aux | grep /usr/bin/dstat | awk '{print $2}')
