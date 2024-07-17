#!/bin/bash
#
# This scripts copy randomly a given number of file to a given destination
#
# Example usage
#
#     ./copy-random.sh /path/to/your/photo_library 10
#
# By default the scripts copies automatically to ./samples but you can 
# provide a third argument to change this behaviour
#

FOLDER=$1
COUNT=${2:-1}
DESTINATION=${3:-./samples}

ls $FOLDER | sort -R |tail -$COUNT |while read FILE; do
  echo "Copy $FILE -> $DESTINATION"
  cp "$FOLDER/$FILE" "$DESTINATION"
done
