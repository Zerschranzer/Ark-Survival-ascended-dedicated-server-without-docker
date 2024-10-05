#!/bin/bash

# ==========================
# ARK Server Restart Manager
# ==========================
# A flexible and efficient script to manage ARK server restarts.
# Users can define their own announcement times and restart intervals.

# ---------- CONFIGURATION ----------
# Define your server instances here (use the names you use in ark_instance_manager.sh)
instances=("instanceexample" "instanceexample")

# Define the exact announcement times in seconds
# Each value represents how many seconds before the restart the message should be sent
announcement_times=(1800 1200 600 180 10)  # 30 min, 20 min, 10 min, 3 min, 10 sec before restart

# Corresponding messages for each announcement time
announcement_messages=(
    "Server restart in 30 minutes"
    "server restart in 20 minutes"
    "Server restart in 10 minutes"
    "Server restart in 3 minutes"
    "Server restart in 10 seconds"
)

# The ark_instance_manager.sh path is set to the directory where your ark_restart_manager.sh is located
script_dir="$(dirname "$(realpath "$0")")"
ark_manager="$script_dir/ark_instance_manager.sh"

# Time to wait after issuing 'saveworld' (in seconds)
save_wait_time=20

# Time to wait between starting instances (in seconds)
start_wait_time=30

# Log file location in the same directory where your ark_restart_manager.sh is located
log_file="$script_dir/ark_restart_manager.log"

# --------------------------------------------- CONFIGURATION ENDS HERE --------------------------------------------- #
#                                                                                         \   |   /                   #
#                               &&& &&  & &&                        .-~~~-.                 .-*-.                     #
#                           & &\/&\|& ()|/ @, &&                .-~~       ~~-.           --  *  --                   #
#                             &\/(/&/&||/& /_/)_&              (               )            '-*-'                     #
#                          &() &\/&|()|/&\/ '%" &               `-.__________.-'          /   |   \                   #
#                             &_\/_&&_/ \|&  _/&_&                                          .-~~~-.                   #
#                        &   && & &| &| /& & % ()& /&&                                  .-~~       ~~-.               #
#                  __      ()&_---()&\&\|&&-&&--%---()~                                (               )              #
#                 / _)                \|||                                              `-.__________.-'              #
#        _.----._/ /                   |||                                                                            #
#       /         /                    |||                                      O                                     #
#    __/ (  | (  |                     |||                                     /|\                                    #
#   /__.-'|_|--|_|                     |||                                     / \                                    #
#   , -=-~  .-^- _, -=-~  .-^- _, -=-~  .-^- _, -=-~  .-^- _, -=-~  .-^- _, -=-~  .-^- _, -=-~  .-^- _, -=-~  .-^- _  #
#######################################################################################################################



# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$log_file"
}

# Function to execute a command for each instance (with optional wait time)
manage_instances() {
    local action=$1
    local wait_time=$2
    for instance in "${instances[@]}"; do
        log_message "Executing '$action' for instance $instance..."
        $ark_manager "$instance" "$action"
        if [ $? -ne 0 ]; then
            log_message "Error: Failed to $action instance $instance."
        fi
        if [ -n "$wait_time" ]; then
            log_message "Waiting $wait_time seconds before proceeding to the next instance..."
            sleep $wait_time
        fi
    done
}

# Function to send RCON command to all instances
send_rcon_to_all() {
    local command=$1
    for instance in "${instances[@]}"; do
        log_message "Sending RCON command '$command' to instance $instance..."
        $ark_manager "$instance" send_rcon "$command"
    done
}

# Function to announce the restart to all players
announce_restart() {
    local total_restart_time=${announcement_times[0]} # Start with the first announcement time

    # Send warnings according to the announcement_times array
    for i in "${!announcement_times[@]}"; do
        local time_before_restart=${announcement_times[$i]}
        local message="${announcement_messages[$i]}"

        # Send the announcement to all instances
        send_rcon_to_all "serverchat $message"
        log_message "Announced: $message."

        # Calculate the time to wait until the next announcement
        if [ $i -lt $((${#announcement_times[@]} - 1)) ]; then
            local next_time=${announcement_times[$i+1]}
            local sleep_time=$(( time_before_restart - next_time ))
            sleep $sleep_time
        fi
    done
}

# Function to save the game world for each instance
save_world() {
    for instance in "${instances[@]}"; do
        log_message "Saving world for instance $instance..."
        $ark_manager "$instance" send_rcon "saveworld"
        log_message "Waiting $save_wait_time seconds to ensure world is saved..."
        sleep $save_wait_time
    done
}

# ---------- MAIN SCRIPT ----------
log_message "Starting ARK server restart process."

# 1. Announce the restart with warning messages
announce_restart

# 2. Save the world for each instance and wait before proceeding
save_world

# 3. Stop the server instances one by one (no wait time between stops)
manage_instances "stop" ""

# 4. Update the server
log_message "Updating all instances..."
$ark_manager update
log_message "Update completed."

# 5. Start the server instances one by one (with wait time between starts)
manage_instances "start" "$start_wait_time"

log_message "ARK servers have been successfully restarted and updated."

