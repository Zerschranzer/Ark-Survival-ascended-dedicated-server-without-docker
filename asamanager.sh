#!/bin/bash

# Define startup parameters
STARTPARAMS="TheIsland_WP?listen?Port=7777?RCONPort=27020?RCONEnabled=True -WinLiveMaxPlayers=50"

# Define the base paths as variables
BASE_DIR="/home/$(whoami)"
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

# Function to set up the server
server_setup() {

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

# Run steamcmd and install the game in the SERVER_FILES_DIR directory
"$STEAMCMD_DIR/steamcmd.sh" +force_install_dir "$SERVER_FILES_DIR" +login anonymous +app_update 2430930 validate +quit

# Copy the Proton prefix to the compatibility data directory
cp -r "$PROTON_DIR/files/share/default_pfx" "$PROTON_PREFIX"

# Start the Ark Server with Proton in the background
"$PROTON_DIR/proton" run "$ARK_EXECUTABLE" $STARTPARAMS &

# Timer
sleep 3

# Print a message in the console in red color
echo -e "\e[31mScript now waits for 1 minutes for the server to start up and will then shut it down.\e[0m"

# Wait for 30 Seconds to allow the server to start up, then shut it down
sleep 60

# Terminate the Ark Server process
pkill -f ArkAscendedServer.exe
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
    export STEAM_COMPAT_DATA_PATH="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$BASE_DIR/Steam"
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
    start_rcon_cli <<EOF
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
    update_server
    start_server
}

# Testfunktion, um RCON-Befehl zu senden
send_rcon() {
   start_rcon_cli <<EOF
$1
EOF
}

# Hauptmenü
if [ -z "$1" ]; then
    echo "ARK Server Management"
    echo "1) Start server"
    echo "2) Stop server"
    echo "3) Restart and update server"
    echo "4) Open RCON console (exit with CTRL+C)"
    echo "5) Download and Setup the Server"
    echo "Please choose an option:"
    read -r option
    # Führen Sie die entsprechende Aktion basierend auf der gewählten Option aus
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
            server_setup
            # Update or add values
            update_or_add_value "SessionSettings" "SessionName"
            update_or_add_value "ServerSettings" "ServerPassword"
            update_or_add_value "ServerSettings" "ServerAdminPassword"
            echo "Server setup completed"
            ;;
        *)
            echo "Invalid option."
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
        setup)
            # Update or add values
            update_or_add_value "SessionSettings" "SessionName"
            update_or_add_value "ServerSettings" "ServerPassword"
            update_or_add_value "ServerSettings" "ServerAdminPassword"
            echo "Server setup completed"
            server_setup
            ;;
        send_rcon)
            send_rcon "$2"
            ;;
        *)
            echo "Invalid option."
            exit 1
            ;;
    esac
fi