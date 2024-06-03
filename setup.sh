#!/bin/bash

# Define base paths as variables, use $(whoami) for the current username
BASE_DIR="/home/$(whoami)"
STEAMCMD_DIR="$BASE_DIR/steamcmd"
SERVER_FILES_DIR="$BASE_DIR/server-files"
PROTON_DIR="$BASE_DIR/GE-Proton9-5"
PROTON_PREFIX="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
ARK_EXECUTABLE="$SERVER_FILES_DIR/ShooterGame/Binaries/Win64/ArkAscendedServer.exe"
CONFIG_FILE="$BASE_DIR/server-files/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini"

# Download the server administration scripts
wget -O "$BASE_DIR/start_stop.sh" "https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/start_stop.sh"
chmod +x start_stop.sh
wget -O "$BASE_DIR/restart_10_cron.sh" "https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/restart_10_cron.sh"
chmod +x restart_10_cron.sh

# Create the steamcmd directory and navigate into it
mkdir -p "$STEAMCMD_DIR"
cd "$STEAMCMD_DIR"

# Download and extract the steamcmd_linux.tar.gz archive
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xvzf steamcmd_linux.tar.gz
rm steamcmd_linux.tar.gz

# Go back to the home directory
cd ~

# Download and extract the GE-Proton9-5.tar.gz archive
wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-5/GE-Proton9-5.tar.gz
tar -xvzf GE-Proton9-5.tar.gz
rm GE-Proton9-5.tar.gz

# Run steamcmd.sh and install the game in the SERVER_FILES_DIR directory
"$STEAMCMD_DIR/steamcmd.sh" +force_install_dir "$SERVER_FILES_DIR" +login anonymous +app_update 2430930 validate +quit

# Create the directory for compatibility data
mkdir -p "$PROTON_PREFIX"

# Copy the Proton prefix to the compatibility data directory
cp -r "$PROTON_DIR/files/share/default_pfx" "$PROTON_PREFIX"

# Set environment variables for Proton
export STEAM_COMPAT_DATA_PATH="$PROTON_PREFIX"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAMCMD_DIR"

# Start the Ark Server with Proton in the background
"$PROTON_DIR/proton" run "$ARK_EXECUTABLE" TheIsland_WP?listen?Port=7777?RCONPort=27020?RCONEnabled=True -WinLiveMaxPlayers=50 &

# Timer
sleep 3

# Print a message in the console in red color
echo -e "\e[31mScript now waits for 3 minutes for the server to start up and will then shut it down.\e[0m"

# Wait for 3 minutes to allow the server to start up, then shut it down
sleep 180

# Terminate the Ark Server process
pkill -f ArkAscendedServer.exe

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
            read -p "Enter the name for your server: " value
        elif [ "$key" == "ServerPassword" ]; then
            read -p "Enter your server password (leave blank if you don't want a password): " value
        elif [ "$key" == "ServerAdminPassword" ]; then
            read -p "Enter an admin password (required for console access): " value
        fi
        sed -i "/$regex/,/^\[/{s/^$key=.*/$key=$value/}" "$CONFIG_FILE"
    else
        # Add the key and value
        if [ "$key" == "SessionName" ]; then
            read -p "Enter the name for your server: " value
        elif [ "$key" == "ServerPassword" ]; then
            read -p "Enter your server password (leave blank if you don't want a password): " value
        elif [ "$key" == "ServerAdminPassword" ]; then
            read -p "Enter an admin password (required for console access): " value
        fi
        sed -i "/$regex/a $key=$value" "$CONFIG_FILE"
    fi
}

# Update or add values
update_or_add_value "SessionSettings" "SessionName"
update_or_add_value "ServerSettings" "ServerPassword"
update_or_add_value "ServerSettings" "ServerAdminPassword"

