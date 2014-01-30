#!/bin/bash
# Program: tmuxrc.sh
# Brief: A simple script that helps user easily connect to multiple hosts by tmux,
#		 especially useful in clustered environments. Can be used by adding it to
#		 the last line of shell run command file.
# Usage: No any parameter needed.
# Version: 1.0
# Built Date: 2014/01/30
# Authur: Sharkz Wang
# E-mail: sharkz.wang@gmail.com

# A prompt which will be invalidated as the timer is timeout 
# Usage: msg_timer MSG DEFAULT_VALUE TIMER
function msg_timer {

    PROMPT=$1
    DEFAULT=${2:-"N"}	# default value is N
    TIMER=${3:-"5"}		# default value is 5 sec

    INPUT=""

	# Prompt is properly set to inform user which its default value is
    if [[ "${DEFAULT}" =~ [yY] ]]; then
        PROMPT="${PROMPT} [Y/n]"
    else
        PROMPT="${PROMPT} [N/y]"
    fi

	# Show input prompt to user
    read -t ${TIMER} -p "${PROMPT} " INPUT

	# Exit if timeout
    if [ "$?" = "142" ]; then
        return 1
    fi
    
	# Default value will be taken if the input is either empty or incorrectly given
    if [[ "${DEFAULT}" =~ [yY] ]] && [[ ! "${INPUT}" =~ [nN] ]]; then
        INPUT="Y"
    elif [[ "${DEFAULT}" =~ [nN] ]] && [[ ! "${INPUT}" =~ [yY] ]]; then
        INPUT="N"
    fi

    if [[ "$INPUT" =~ [nN] ]]; then
        return 1
    else
        return 0
    fi
}

# Procedure is guarded by an input prompt with invalidation timer to prevent infinite tmux recursive call
if ! msg_timer "Start a new tmux session or attach an existing one ?" y 3; then
    exit 0
fi

# Only when there is no any existing session, a new session is created
tmux attach && exit 0

# To avoid collisions of session names, session names are named after its creation time 
SESSION_NAME=$(date +%y%m%d%H%M%S)
# Hosts to be connected
HOSTNAME='linux'

# The 1st window is for irssi
tmux new-session -d -s ${SESSION_NAME} -n 'irssi' 'irssi'

# The 2nd window is for ptt, a popular bbs site in Taiwan
tmux new-window -t ${SESSION_NAME}:1 -n "ptt" "ssh bbsu@ptt.cc"

# The rest of windows are for all hosts specified to be connected
for i in `seq 1 15`
do
    tmux new-window -t ${SESSION_NAME}:$((i+1)) -n "${HOSTNAME}${i}" "ssh ${HOSTNAME}${i}"
done

# Set the foregrounded window to the first connected host
tmux select-window -t ${SESSION_NAME}:2

# Start tmux
tmux -2 attach-session -t ${SESSION_NAME}
