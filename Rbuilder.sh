#!/bin/bash

#######################################
# Restores terminal state.
# Globals:
#   None
# Arguments:
#   None
#######################################
cleanup() {
  tput rmcup
  exit
}

#######################################
# Explains what a trailing / does in rsync.
# Globals:
#   None
# Arguments:
#   None
#######################################
source_boilerplate() {
  echo -e "\e[1;32mPlease Enter the Source Directory\e[0m"
  echo "###########################################################"
  echo "# If you don't want containing directories to be placed   #"
  echo "# inside the root source directory like below.            #"
  echo "# /Destination                                            #"
  echo "#          |__ /Home                                      #"
  echo "#                 |__ /User1                              #"
  echo "#                 |__ /User2                              #"
  echo "#                                                         #"
  echo "# Then include a trailing / when entering the source.     #"
  echo "# After entering the trailing / it should look like this. #"
  echo "# /Destination                                            #"
  echo "#          |__ /User1                                     #"
  echo "#          |__ /User2                                     #"
  echo "#                                                         #"
  echo "# Additionally you can use tab completion and you should  #"
  echo "# get the same results as adding a trailing /.            #"
  echo "###########################################################"
  echo ""
}

# Uses the function cleanup to be passed when canceling this script.
trap cleanup SIGINT
# Saves the terminal state before this applications main functions are executed.
tput smcup
clear

# Allows the user to enter a source directory and re-input it if incorrect.
while true; do
  source_boilerplate
  read -e -p "Enter the source directory: " source
  if [[ -d "${source}" ]]; then
    clear
    echo "Input: ${source}"
    read -e -p "Does this input look correct? (yes/no): " entered_source
    if [[ "${entered_source}" == "yes" ]]; then
      clear
      break
    else
      echo "Please enter the source again"
      sleep 1
      clear
    fi            
  else
    echo "The source does not exist please enter again."
    sleep 1
    clear
  fi
done

# Allows the user to enter a destination directory and re-input it if incorrect.
while true; do
  read -e -p "Enter the destination directory: " destination
  clear
  if [[ -d "${destination}" ]]; then
    clear
    echo "Input: ${destination}"
    read -e -p "Does this input look correct? (yes/no): " entered_destination
    if [[ "${entered_destination}" == "yes" ]]; then
      clear
      break
    else
      echo "Please enter the destination again"
      sleep 1
      clear
    fi            
  else
    echo "The destination does not exist please enter again."
    sleep 1
    clear
  fi
done

read -e -p "Do you want to add any options to the rsync command? (yes/no): " add_options
clear

while true; do
  options=""
  if [[ "${add_options}" == "yes" ]]; then
    echo "Available rsync options:"
    echo "1.  --delete:   Files not present in the source directory are deleted from the destination directory."
    echo "2.  --update:   skip files that are newer on the destination than on the source"
    echo "3.  --compress: Compress file data during the transfer"
    echo "4.  --exclude:  Exclude files matching a given PATTERN"
    echo "5.  --include:  Include files matching a given PATTERN"
    echo "6.  --dry-run:  Perform a trial run with no changes made"
    echo "7.  --bwlimit:  Limit I/O bandwidth; KBytes per second"
    echo "8.  --checksum: Skip based on checksum, not mod-time & size"
    echo "9.  --partial:  Keep partially transferred files"     

echo ""
read -e -p "Enter the option numbers you want to add (separated by spaces): " -a selected_options

    for option in "${selected_options[@]}"; do
      case "${option}" in
        1) options+=" --delete" 
           ;;
        2) options+=" --update" 
           ;;
        3) options+=" --compress" 
           ;;
        4) read -p "Enter the pattern to exclude: " pattern
           options+=" --exclude=${pattern}" 
           ;;
        5) read -p "Enter the pattern to include: " pattern
           options+=" --include=${pattern}" 
           ;;
        6) options+=" --dry-run" 
           ;;
        7) read -p "Enter the bandwidth limit (KB/s): " bwlimit
           options+=" --bwlimit=${bwlimit}" 
           ;;
        8) options+=" --checksum" 
           ;;
        9) options+=" --partial" 
           ;;
        *) echo "Invalid option: ${option}" 
           ;;
      esac
    done 
  fi
    clear

command="rsync -avh --info=progress2${options} \"${source}\" \"${destination}\""
clear

echo "The rsync command to be executed is: ${command}"
read -e -p "Do you want to run this command? (yes/no): " run_command
clear

  if [[ "${run_command}" == "yes" ]]; then
    eval "${command}"
    echo ""
    read -e -p "Rsync is finished press enter to continue..."
    break
  else
    echo "Command execution aborted. Do you want to re-input your rsync options?"
    read -e -p "(yes/no): " reinput
    if [[ "${reinput}" != "yes" ]]; then
      break
    else
      add_options="yes"
      clear
    fi
  fi
done

# Restores the terminal to its state before this script was executed.
tput rmcup