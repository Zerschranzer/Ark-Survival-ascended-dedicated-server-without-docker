#!/bin/bash

# Define the startup parameters as variables
STARTPARAMS="TheIsland_WP?listen?Port=7777?RCONPort=27020?RCONEnabled=True -WinLiveMaxPlayers=50"

# Define the base paths as variables
BASE_DIR="/home/$(whoami)"
STEAMCMD_DIR="$BASE_DIR/steamcmd"
SERVER_FILES_DIR="$BASE_DIR/server-files"
PROTON_DIR="$BASE_DIR/GE-Proton9-5"
ARK_EXECUTABLE="$SERVER_FILES_DIR/ShooterGame/Binaries/Win64/ArkAscendedServer.exe"
CONFIG_FILE="$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/GameUserSettings.ini"
RCON_CLI_DIR="$BASE_DIR/rcon-0.10.3-amd64_linux"

# Set the environment variables for Proton
export STEAM_COMPAT_DATA_PATH="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$BASE_DIR/Steam"

# Function to update the server
update_server() {
    echo "Updating server..."
    "$STEAMCMD_DIR/steamcmd.sh" +force_install_dir "$SERVER_FILES_DIR" +login anonymous +app_update 2430930 validate +quit
    echo "Server updated."
}

# Function to check the server status
check_server_status() {
    echo "Checking server status..."
    for i in {1..60}; do # Wait up to 60 seconds
        if pgrep -f ArkAscendedServer.exe > /dev/null; then
            echo "The server is running."
            return 0
        else
            echo "Waiting for the server to start..."
            sleep 1
        fi
    done
    echo "The server could not be started."
    return 1
}

# Function to start the server with the defined parameters
start_server() {
    # Update the server before starting
    update_server

    echo "Starting server..."
    "$PROTON_DIR/proton" run "$ARK_EXECUTABLE" $STARTPARAMS > /dev/null 2>&1 &
    sleep 5 # Short pause to give the server time to start

    # Check the server status
    if check_server_status; then
        echo "Server successfully started."
    else
        echo "Error: Server could not be started."
    fi
}

# Function to stop the server
stop_server() {
    echo "Saving server data..."
    "$BASE_DIR/start_stop.sh" 4 <<EOF
saveworld
EOF
    echo "Server data saved. Stopping server..."
    sleep 10
    pkill -f ArkAscendedServer.exe
    echo "Server stopped."
}

# Function to download and start rcon_cli
start_rcon_cli() {
    if [ ! -d "$RCON_CLI_DIR" ]; then
        echo "Downloading rcon_cli..."
        wget https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz
        tar -xvzf rcon-0.10.3-amd64_linux.tar.gz
        rm rcon-0.10.3-amd64_linux.tar.gz
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
    update_server
    start_server
}

# Main menu
if [ -z "$1" ]; then
    echo "ARK Server Management"
    echo "1) Start server and update it"
    echo "2) Stop server"
    echo "3) Restart and update server"
    echo "4) Open RCON console (exit with CTRL+C)"
    echo "Please choose an option:"
    read -r option
else
    option=$1
fi

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
    *)
        echo "Invalid option."
        ;;
esac
