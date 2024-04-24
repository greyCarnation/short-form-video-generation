#!/bin/bash

# Get all directories in the current directory
dirs=($(\ls -d */ | sed 's/\///g'))

# Loop through each element of the array
for dir in "${dirs[@]}"
do
  cd "$dir"/00_original || return 
  sh catVideos.sh
  rm videoList.txt *.MOV
  mv *.mov "${dir}.mov"
  cd ../..
done 

exit

