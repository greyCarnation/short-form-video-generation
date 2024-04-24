#!/bin/bash

# Get all directories in the current directory
dirs=($(\ls -d */ | sed 's/\///g'))

# Loop through each element of the array
for dir in "${dirs[@]}"
do
  cd "$dir" || return 
  sh avProcess.sh create
  cd .. || return
done 

exit

