#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Deploy terraform template multiple times with -c."
   echo
   echo "Syntax: multi_deploy [-c|-h]"
   echo "options:"
   echo "c     count"
   echo "h     Print this Help."
   echo
}

# Set variables
Count=0
Files=("main.tf" "output.tf" "provider.tf" "set-exports.sh" "variables.tf" "versions.tf" "templates")

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

echo "Deploy $Count evironments"
 
for (( c=1; c<=$Count; c++ ))
do
  Folder="deployments/$c"
  echo "Create Folder $Folder"
  mkdir -p $Folder
  for File in $"${Files[@]}"; 
  do
    cp -r $File $Folder
  done
  cd $Folder
  source ./set-exports.sh
  terraform init
  terraform plan
  terraform apply -auto-approve
  terraform output > terraform-run.log
  sed "/^EOT/c\ " terraform-run.log | sed "/hack_write_up = <<EOT/c\ " | sed 's/\\{/{/g' > "$c.md"

  cd ../../

	sleep 1
done
