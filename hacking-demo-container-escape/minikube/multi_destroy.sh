#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Destroy terraform template multiple times with -c."
   echo
   echo "Syntax: multi_destroy [-c|-h]"
   echo "options:"
   echo "c     count"
   echo "h     Print this Help."
   echo
}

# Set variables
Count=0

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hc:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      c) # Enter a count
         Count=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

if [ $Count == 0 ];
then
  Help
  exit;
fi

echo "Destroy $Count evironments"
 
for (( c=1; c<=$Count; c++ ))
do
  Folder="deployments/$c"
  
  cd $Folder
  source ./set-exports.sh
  terraform apply -destroy -auto-approve

  cd ../../
	
	sleep 1
done
