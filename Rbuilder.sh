#!/usr/bin/env bash

#######################################
# Restores terminal state.
# Globals:
#   None
# Arguments:
#   None
#######################################
cleanup() {
  current_session_end_session=$(tmux display-message -p '#S')
  tmux kill-session -t $current_session_end_session
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
  echo -e "\e[1;32mPlease Enter the Source Directory\e[0m                            \e[1;32mTmux Available Options\e[0m        "
  echo "###########################################################  ###########################################################"
  echo "# If you don't want containing directories to be placed   #  # 1. Switch session:   Crtl+B release, then press S       #"
  echo "# inside the root source directory like below.            #  # 2. Detatch session:  Ctrl+B release, then press D       #"
  echo "# /Destination                                            #  # 3. Previous Session: Ctrl+B release, then press (       #"
  echo "#          |__ /Home                                      #  # 4. Next session:     Ctrl+B release, then press )       #"
  echo "#                 |__ /User1                              #  #                                                         #"
  echo "#                 |__ /User2                              #  #                                                         #"
  echo "#                                                         #  #                                                         #"
  echo "# Then include a trailing / when entering the source.     #  #                                                         #"
  echo "# After entering the trailing / it should look like this. #  #                                                         #"
  echo "# /Destination                                            #  #                                                         #"
  echo "#          |__ /User1                                     #  #                                                         #"
  echo "#          |__ /User2                                     #  #                                                         #"
  echo "#                                                         #  #                                                         #"
  echo "# Additionally you can use tab completion and you should  #  #                                                         #"
  echo "# get the same results as adding a trailing /.            #  #                                                         #"
  echo "###########################################################  ###########################################################"
  echo ""
}

#######################################
# Starts a new tmux session and renames
# it to temp_name. this is needed to
# allow this script to be a single file.
# Globals:
#  $TMUX
# Arguments:
#  None
#######################################
start_tmux(){
  tmux_session="temp_name"

  # -z checks if the variable is an empy string.
  # This if statement is needed to test weather the user is currently in a tmux session or not.
  # If the user is not in a tmux session it will create one and then send a command to re-run
  # this script inside the tmux session. 
  if [[ -z "$TMUX" ]]; then
    echo "Creating new tmux session..."
    echo "This will take at least 5 seconds."
    tmux new-session -s "$tmux_session" -d
    sleep 5
    tmux send-keys -t "$tmux_session" 'bash Rbuilder.sh' C-m
    tmux attach-session -t "$tmux_session"
    exit

  # -n checks if the variable is a non empty string.
  # This elif is needed to check if user is currently in a tmux session, so it can gather the current session name. 
  elif [[ -n "$TMUX" ]]; then
    # Variable to store name of current tmux session. 
    current_session=$(tmux display-message -p '#S')
    tmux_user_session=$(echo "$current_session" | grep -o '[a-zA-Z]\{3\}[0-9]\{1,4\}')
    other_tmux_session=$(echo "$current_session" | grep 'Rsync[0-9]*')

    # This if statement is needed to check weather the current tmux session is named Rsync. If it is not it creates
    # a new session named Rsync and re-runs the script inside the Rsync tmux session. When this script is re-ran
    # it uses this statement again to be able to continue the script properly without creating an unnessesary loop.
    if [[ $current_session == $tmux_session ]]; then
      # Get all tmux sessions and filter for those starting with "Rsync"
      sessions=$(tmux list-sessions -F "#{session_name}" | grep '^Rsync')
    
      # Initialize max_number
      max_number=0
    
      # Loop through the filtered sessions to find the highest number
      for session in $sessions; do
        # Extract the number from the session name
          if [[ $session =~ ^Rsync([0-9]+)$ ]]; then
              number=${BASH_REMATCH[1]}
              if (( number > max_number )); then
                  max_number=$number
              fi
          fi
      done
    
      # Increment the highest number found
      new_number=$((max_number + 1))
      
      # Create a new tmux session with the incremented number
      new_session_name="Rsync$new_number"
      echo "Renameing tmux session..."
      tmux rename-session -t $tmux_session $new_session_name
      sleep 2
    elif [[ $current_session == $tmux_user_session || $current_session == $other_tmux_session ]]; then
      :
    else
      echo "Creating new tmux session..."
      echo "This will take at least 5 seconds."
      tmux new-session -s "$tmux_session" -d
      sleep 5
      tmux send-keys -t "$tmux_session" 'bash Rbuilder.sh' C-m
      tmux switch -t "$tmux_session"
      exit
    fi

  fi
}

# Starts a new tmux session and renames it.
start_tmux

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

origional_source=$source

# Needed to grab the users directory name out of the source entry for the rsync command.
# This will be used to rename the tmux session to the users directory name.
user_directory=$(echo "$source" | grep -o '[a-zA-Z]\{3\}[0-9]\{1,4\}')

# -n checks if the variable is a non empty string.
if [[ -n $user_directory ]]; then
  echo "You are rsyncing a user directory."
  echo "Renaming session to $user_directory..."
  tmux rename-session -t 'Rsync[0-9]*' $user_directory
  sleep 5
  clear
else
  :
fi

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

    current_session_end_session=$(tmux display-message -p '#S')
    tmux kill-session -t $current_session_end_session
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