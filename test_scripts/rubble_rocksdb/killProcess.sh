#!bin/bash

# set -ex

PATTERN='recovery'


for i in "$@"
do
case $i in
    -p=*|--pattern=*)
    PATTERN="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

# kill the old process
kill $(ps aux | grep $PATTERN | awk '{print $2}')

