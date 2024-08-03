#!/bin/bash

SCRIPT_VERSION="1.0.1"

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

# Path to the asamanager configuration file
SCRIPT_CONFIG="script_config.cfg"

# Define the base paths as variables
BASE_DIR="$(pwd)"
STEAMCMD_DIR="$BASE_DIR/steamcmd"
SERVER_FILES_DIR="$BASE_DIR/server-files"
PROTON_DIR="$BASE_DIR/GE-Proton9-5"
PROTON_PREFIX="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
ARK_EXECUTABLE="$SERVER_FILES_DIR/ShooterGame/Binaries/Win64/ArkAscendedServer.exe"
CONFIG_FILE="$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini"
RCON_CLI_DIR="$BASE_DIR/rcon-0.10.3-amd64_linux"

# Set the environment variables for Proton
export STEAM_COMPAT_DATA_PATH="$PROTON_PREFIX"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$BASE_DIR/Steam"


# Define URLS for Steamcmd, Proton, and rconcli
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-5/GE-Proton9-5.tar.gz"
RCONCLI_URL="https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz"


#Creates Config file, if it doesnt exist
check_and_create_config() {
    if [ ! -f $SCRIPT_CONFIG ]; then
        echo "The configuration file does not exist. It is being created."
        echo 'STARTPARAMS="TheIsland_WP?listen?Port=7777?RCONPort=27020?RCONEnabled=True -WinLiveMaxPlayers=50 -mods="' > $SCRIPT_CONFIG
    fi
    
check_for_updates() {
    echo "Checking for updates..."
    
    # url to newest raw version
    GITHUB_SCRIPT_URL="https://raw.githubusercontent.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/main/asamanager.sh"
    
    # download newest version
    LATEST_VERSION=$(curl -s $GITHUB_SCRIPT_URL | grep "^SCRIPT_VERSION=" | cut -d'"' -f2)
    
    if [ -z "$LATEST_VERSION" ]; then
        echo "Error: Unable to retrieve the latest version number."
        return 1
    fi

    if [ "$LATEST_VERSION" != "$SCRIPT_VERSION" ]; then
        echo "A new version ($LATEST_VERSION) is available. You are currently running version $SCRIPT_VERSION."
        read -p "Do you want to update? (y/n): " choice
        case "$choice" in 
            y|Y ) 
                echo "Updating script..."
                if curl -o asamanager.sh.tmp $GITHUB_SCRIPT_URL && mv asamanager.sh.tmp asamanager.sh; then
                    chmod +x asamanager.sh
                    echo "Update completed. Please restart the script."
                    exit 0
                else
                    echo "Error: Update failed. Please try again or update manually."
                    rm -f asamanager.sh.tmp
                fi
                ;;
            * ) 
                echo "Update skipped."
                ;;
        esac
    else
        echo "You are running the latest version ($SCRIPT_VERSION)."
    fi
}

# Function to set up the server
server_setup() {
check_and_create_config
load_startparams
change_map
change_mods
# Create necessary directories
mkdir -p "$STEAMCMD_DIR" "$PROTON_DIR" "$RCON_CLI_DIR" "$PROTON_PREFIX"

# Download and unpack Steamcmd
wget -O "$STEAMCMD_DIR/steamcmd_linux.tar.gz" "$STEAMCMD_URL"
tar -xzvf "$STEAMCMD_DIR/steamcmd_linux.tar.gz" -C "$STEAMCMD_DIR"
rm "$STEAMCMD_DIR/steamcmd_linux.tar.gz"

# Download and unpack Proton
wget -O "$PROTON_DIR/GE-Proton9-5.tar.gz" "$PROTON_URL"
tar -xzvf "$PROTON_DIR/GE-Proton9-5.tar.gz" -C "$PROTON_DIR" --strip-components=1
rm "$PROTON_DIR/GE-Proton9-5.tar.gz"

# Download and unpack rcon-cli
wget -O "$RCON_CLI_DIR/rcon-0.10.3-amd64_linux.tar.gz" "$RCONCLI_URL"
tar -xzvf "$RCON_CLI_DIR/rcon-0.10.3-amd64_linux.tar.gz" -C "$RCON_CLI_DIR" --strip-components=1
rm "$RCON_CLI_DIR/rcon-0.10.3-amd64_linux.tar.gz"

# Running function to update or install ASA Server
update_server

# Copy the Proton prefix to the compatibility data directory
cp -r "$PROTON_DIR/files/share/default_pfx" "$PROTON_PREFIX"

# Start the Ark Server with Proton in the background
"$PROTON_DIR/proton" run "$ARK_EXECUTABLE" $STARTPARAMS &

# Timer
sleep 3

# Print a message in the console in red color
echo -e "\e[32mScript now waits for 1 minutes for the server to start up and will then shut it down.\e[0m"

# Wait for 30 Seconds to allow the server to start up, then shut it down
sleep 60

# Terminate the Ark Server process
pkill -f ArkAscendedServer.exe

# Update or add values
update_or_add_value "SessionSettings" "SessionName"
update_or_add_value "ServerSettings" "ServerPassword"
update_or_add_value "ServerSettings" "ServerAdminPassword"
echo -e "\e[32mServer Setup Completed\e[0m"
}

# Function to update or add a value in the INI file
update_or_add_value() {
    local section=$1
    local key=$2
    local value
    local regex="^\[$section\]"

    # Check if the section exists
    if ! grep -q "$regex" "$CONFIG_FILE"; then
        # Add the section if it doesn't exist
        echo "[$section]" >> "$CONFIG_FILE"
    fi

    # Check if the key exists
    if grep -q "^$key=" "$CONFIG_FILE"; then
        # Prompt for the new value and update it
        if [ "$key" == "SessionName" ]; then
            echo -ne "\e[38;5;214mEnter the name for your server: \e[0m"
            read value
        elif [ "$key" == "ServerPassword" ]; then
            echo -ne "\e[38;5;214mEnter your server password (leave blank if you don't want a password): \e[0m"
            read value
        elif [ "$key" == "ServerAdminPassword" ]; then
            echo -ne "\e[38;5;214mEnter an admin password (required for console access): \e[0m"
            read value
        fi
        sed -i "/$regex/,/^\[/{s/^$key=.*/$key=$value/}" "$CONFIG_FILE"
    else
        # Add the key and value
        if [ "$key" == "SessionName" ]; then
            echo -ne "\e[38;5;214mEnter the name for your server: \e[0m"
            read value
        elif [ "$key" == "ServerPassword" ]; then
            echo -ne "\e[38;5;214mEnter your server password (leave blank if you don't want a password): \e[0m"
            read value
        elif [ "$key" == "ServerAdminPassword" ]; then
            echo -ne "\e[38;5;214mEnter an admin password (required for console access): \e[0m"
            read value
        fi
        sed -i "/$regex/a $key=$value" "$CONFIG_FILE"
    fi
}

# Function to update the server
update_server() {
    echo "Updating server..."
    if "$STEAMCMD_DIR/steamcmd.sh" +force_install_dir "$SERVER_FILES_DIR" +login anonymous +app_update 2430930 validate +quit; then
        echo -e "\e[32mServer Updated.\e[0m"
    else
        echo -e "\e[31mServer could not be updated.\e[0m"
    fi
}

check_server_status() {
    if pgrep -f ArkAscendedServer.exe > /dev/null; then
        echo -e "\e[32mThe server is running.\e[0m"
           start_rcon_cli <<EOF
ListPlayers
EOF
    else
        echo -e "\e[31mThe Server is offline.\e[0m"
    fi
}


# Function to start the server with the defined parameters
start_server() {
    if pgrep -f ArkAscendedServer.exe > /dev/null; then
        echo -e "\e[32mServer already running.\e[0m"
    else
        check_and_create_config
        load_startparams
        update_server
        echo "Starting server..."
        "$PROTON_DIR/proton" run "$ARK_EXECUTABLE" $STARTPARAMS > /dev/null 2>&1 &
        sleep 5 # Short pause to give the server time to start

        # Check if the server started successfully
        if pgrep -f ArkAscendedServer.exe > /dev/null; then
            echo -e "\e[32mServer started successfully.\e[0m"
        else
            echo -e "\e[31mError, server could not be started.\e[0m"
        fi
    fi
}

# Function to stop the server
stop_server() {
    if ! pgrep -f ArkAscendedServer.exe > /dev/null; then
        echo -e "\e[31mServer already offline.\e[0m"
        return
    fi
    echo "Saving server data..."
    start_rcon_cli <<EOF
saveworld
EOF
    echo "Server data saved. Stopping server..."
    sleep 10
    pkill -f ArkAscendedServer.exe
    echo -e "\e[31mServer stopped.\e[0m"
}

# Function to download and start rcon_cli
start_rcon_cli() {
    if [ ! -d "$RCON_CLI_DIR" ]; then
        echo "Downloading rcon_cli..."
        wget -O "$RCON_CLI_DIR/rcon-0.10.3-amd64_linux.tar.gz" "$RCONCLI_URL"
        tar -xzvf "$RCON_CLI_DIR/rcon-0.10.3-amd64_linux.tar.gz" -C "$RCON_CLI_DIR" --strip-components=1
        rm "$RCON_CLI_DIR/rcon-0.10.3-amd64_linux.tar.gz"
        echo "rcon_cli downloaded and extracted."
    fi

    # Read RCON_PORT and RCON_PASSWORD from the GameUserSettings.ini
    RCON_PORT=$(grep -oP 'RCONPort=\K\d+' "$CONFIG_FILE")
    RCON_PASSWORD=$(grep -oP 'ServerAdminPassword=\K\S+' "$CONFIG_FILE")

    echo "Starting rcon_cli..."
    "$RCON_CLI_DIR/rcon" -a localhost:$RCON_PORT -p $RCON_PASSWORD
}

# Function to restart and update the server
restart_and_update_server() {
    stop_server
    start_server
}

# function to send rcon commands
send_rcon() {
   start_rcon_cli <<EOF
$1
EOF
}

# function to load startparameters from script_config.cfg
load_startparams() {
    if [[ -f "$SCRIPT_CONFIG" ]]; then
        source "$SCRIPT_CONFIG"
    else
       echo -e "\e[31mConfig file not found\e[0m"
        exit 1
    fi
}

# function to change map
change_map() {
    check_and_create_config
    load_startparams
    echo -e "\e[32mCurrent Map: ${STARTPARAMS%%\?*}\e[0m"
    echo -e "\e[38;5;214mChoose the map by pressing a number:"
    echo
    echo -e "1) TheIsland_WP"
    echo -e "2) ScorchedEarth_WP"
    echo -e "3) TheCenter_WP"
    echo -e "4) Svartalfheim_WP \e[31m(MOD-Map)\e[0m"
    echo -e "\e[33m5) Type in your own\e[0m"
    echo -ne "\e[38;5;214mPlease enter your choice (leave blank to cancel): \e[0m"
    read -r map_choice
    case $map_choice in
        1)
            new_map_name="TheIsland_WP"
            ;;
        2)
            new_map_name="ScorchedEarth_WP"
            ;;
        3)
            new_map_name="TheCenter_WP"
            ;;
        4)
            new_map_name="Svartalfheim_WP"
            mod_id="962796" # Mod-ID for Svartalfheim_WP
            ;;
        5)
            echo "Please enter the name of the new map:"
            read -r new_map_name
            ;;
        *)
            echo -e "\e[31mNo changes made.\e[0m"
            return
            ;;
    esac
    if [ -z "$new_map_name" ]; then
            echo -e "\e[31mNo changes made.\e[0m"
        return
    fi
    if [ "$new_map_name" == "Svartalfheim_WP" ]; then
        STARTPARAMS="${new_map_name}?listen?Port=7777?RCONPort=27020?RCONEnabled=True -WinLiveMaxPlayers=50 -mods=${mod_id}"
    else
        STARTPARAMS="${new_map_name}?${STARTPARAMS#*\?}"
    fi
    echo "STARTPARAMS=\"$STARTPARAMS\"" > "$SCRIPT_CONFIG"
    echo -e "\e[32mThe map has been updated: $STARTPARAMS\e[0m"
}


# function to enter Mod-IDs
change_mods() {
    check_and_create_config
    load_startparams
    echo -e "\e[32mCurrent Mods: ${STARTPARAMS##*-mods=}\e[0m"
    echo -e "\e[38;5;214mPlease enter the new mod IDs, separated by commas. (type 'clear' to remove all mods, leave blank to cancel without making changes)\e[0m"
    read -r new_mod_ids
    if [ -z "$new_mod_ids" ]; then
        echo -e "\e[31mNo changes made.\e[0m"
        return
    elif [ "$new_mod_ids" == "clear" ]; then
        new_mod_ids=""
        echo -e "\e[31mAll Mod-IDs have been cleared.\e[0m"
    fi
    local params_before_mods="${STARTPARAMS%%-mods=*}"
    STARTPARAMS="${params_before_mods}-mods=${new_mod_ids}"
    echo "STARTPARAMS=\"$STARTPARAMS\"" > "$SCRIPT_CONFIG"
    echo -e "\e[32mMod-IDs have been updated: $STARTPARAMS\e[0m"
}


# Main menu
if [ -z "$1" ]; then
    echo -e "\e[38;5;214mARK Server Management\e[0m"
    echo
    echo -e "\e[38;5;214m1) Start and Update Server\e[0m"
    echo -e "\e[38;5;214m2) Stop Server\e[0m"
    echo -e "\e[38;5;214m3) Restart and Update Server\e[0m"
    echo -e "\e[38;5;214m4) Open RCON Console (exit with CTRL+C)\e[0m"
    echo -e "\e[38;5;214m5) Change Map\e[0m"
    echo -e "\e[38;5;214m6) Change Mods\e[0m"
    echo -e "\e[38;5;214m7) Check Server Status\e[0m"
    echo -e "\e[34m8) Download and Setup the Server\e[0m"
    echo -e "\e[38;5;214m9) Help\e[0m"
    echo -e "\e[38;5;214m10) Check for script updates\e[0m"
    echo -e "\e[38;5;214mPlease choose an option:\e[0m"

    read -r option
    case $option in
        1)
            start_server
            ;;
        2)
            stop_server
            ;;
        3)
            restart_and_update_server
            ;;
        4)
            start_rcon_cli
            ;;
        5)
            change_map
            ;;
        6)
            change_mods
            ;;
        7)
            check_server_status
            ;;
        8)
            server_setup
            ;;
        9)
            echo "Available command-line options:"
            echo "  start       - Start the ARK server"
            echo "  stop        - Stop the ARK server"
            echo "  restart     - Restart and update the ARK server"
            echo "  console     - Open RCON console"
            echo "  status      - Shows the ARK server status"
            echo "  setup       - Download and setup the server"
            echo "  send_rcon   - Send a command to the ARK server via RCON"
            echo "  help        - Display this help message"
            echo "  for example: ./asamanager.sh restart   <---- this would restart the Server, without entering the main menu"
            ;;
         10)
            check_for_updates
            ;;
        *)
            echo "Invalid option selected."
            ;;
    esac
else
    case "$1" in
        start)
            start_server
            ;;
        stop)
            stop_server
            ;;
        restart)
            restart_and_update_server
            ;;
        console)
            start_rcon_cli
            ;;
        status)
            check_server_status
            ;;
        setup)
            server_setup
            ;;
        send_rcon)
            send_rcon "$2"
            ;;
        help)
            echo "Available command-line options:"
            echo "  start       - Start the ARK server"
            echo "  stop        - Stop the ARK server"
            echo "  restart     - Restart and update the ARK server"
            echo "  console     - Open RCON console"
            echo "  status      - Shows the ARK server status"
            echo "  setup       - Download and setup the server"
            echo "  send_rcon   - Send a command to the ARK server via RCON"
            echo "  help        - Display this help message"
            echo "  for example: ./asamanager.sh restart   <---- this would restart the Server, without entering the main menu"
            ;;
        *)
            echo "Invalid command-line option."
            exit 1
            ;;
    esac
fi
