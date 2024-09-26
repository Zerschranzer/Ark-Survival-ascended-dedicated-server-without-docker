#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

# Base directory for all instances
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTANCES_DIR="$BASE_DIR/instances"

# Define the base paths as variables
STEAMCMD_DIR="$BASE_DIR/steamcmd"
SERVER_FILES_DIR="$BASE_DIR/server-files"
PROTON_VERSION="GE-Proton9-5"
PROTON_DIR="$BASE_DIR/$PROTON_VERSION"
RCONCLI_VERSION="0.10.3"
RCON_CLI_DIR="$BASE_DIR/rcon-$RCONCLI_VERSION-amd64_linux"

# Define URLS for Steamcmd, Proton, and rconcli
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$PROTON_VERSION/$PROTON_VERSION.tar.gz"
RCONCLI_URL="https://github.com/gorcon/rcon-cli/releases/download/v$RCONCLI_VERSION/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz"

# Function to install base server
install_base_server() {
    echo "Installing base server..."

    # Create necessary directories
    mkdir -p "$STEAMCMD_DIR" "$PROTON_DIR" "$RCON_CLI_DIR" "$SERVER_FILES_DIR"

    # Download and unpack Steamcmd
    if [ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
        echo "Downloading SteamCMD..."
        wget -O "$STEAMCMD_DIR/steamcmd_linux.tar.gz" "$STEAMCMD_URL"
        tar -xzvf "$STEAMCMD_DIR/steamcmd_linux.tar.gz" -C "$STEAMCMD_DIR"
        rm "$STEAMCMD_DIR/steamcmd_linux.tar.gz"
    else
        echo "SteamCMD already installed."
    fi

    # Download and unpack Proton
    if [ ! -d "$PROTON_DIR/files" ]; then
        echo "Downloading Proton..."
        wget -O "$PROTON_DIR/$PROTON_VERSION.tar.gz" "$PROTON_URL"
        tar -xzvf "$PROTON_DIR/$PROTON_VERSION.tar.gz" -C "$PROTON_DIR" --strip-components=1
        rm "$PROTON_DIR/$PROTON_VERSION.tar.gz"
    else
        echo "Proton already installed."
    fi

    # Download and unpack rcon-cli
    if [ ! -f "$RCON_CLI_DIR/rcon" ]; then
        echo "Downloading rcon-cli..."
        wget -O "$RCON_CLI_DIR/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz" "$RCONCLI_URL"
        tar -xzvf "$RCON_CLI_DIR/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz" -C "$RCON_CLI_DIR" --strip-components=1
        rm "$RCON_CLI_DIR/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz"
    else
        echo "rcon-cli already installed."
    fi

    # Install/Update ARK server
    echo "Installing/Updating ARK server..."
    "$STEAMCMD_DIR/steamcmd.sh" +force_install_dir "$SERVER_FILES_DIR" +login anonymous +app_update 2430930 validate +quit

    echo -e "\e[32mBase server installation completed.\e[0m"
}

# Function to initialize Proton prefix
initialize_proton_prefix() {
    local instance=$1
    local proton_prefix="$SERVER_FILES_DIR/steamapps/compatdata/2430930"

    # Ensure the directory exists
    mkdir -p "$proton_prefix"

    # Copy the default Proton prefix
    cp -r "$PROTON_DIR/files/share/default_pfx/." "$proton_prefix/"

    # Set permissions
    chmod -R 755 "$proton_prefix"

    echo "Proton prefix initialized for instance: $instance"
}

# Function to list all instances
list_instances() {
    echo "Available instances:"
    ls -1 "$INSTANCES_DIR" 2>/dev/null || echo "No instances found."
}

# Function to create or edit instance configuration
edit_instance_config() {
    local instance=$1
    local config_file="$INSTANCES_DIR/$instance/instance_config.ini"

    # Create config file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        echo "[ServerSettings]" > "$config_file"
        echo "ServerName=ARK Server $instance" >> "$config_file"
        echo "ServerPassword=" >> "$config_file"
        echo "ServerAdminPassword=adminpassword" >> "$config_file"
        echo "MaxPlayers=70" >> "$config_file"
        echo "MapName=TheIsland_WP" >> "$config_file"
        echo "RCONPort=27020" >> "$config_file"
        echo "QueryPort=27015" >> "$config_file"
        echo "Port=7777" >> "$config_file"
        echo "ModIDs=" >> "$config_file"
        echo "SaveDir=$instance" >> "$config_file"
        echo "ClusterID=" >> "$config_file"
    fi

    # Open the config file in the default text editor
    if command -v nano >/dev/null 2>&1; then
        nano "$config_file"
    elif command -v vim >/dev/null 2>&1; then
        vim "$config_file"
    else
        echo "No suitable text editor found. Please edit $config_file manually."
    fi
}

# Function to load instance configuration
load_instance_config() {
    local instance=$1
    local config_file="$INSTANCES_DIR/$instance/instance_config.ini"

    if [ -f "$config_file" ]; then
        # Read configuration into variables
        SERVER_NAME=$(grep "ServerName=" "$config_file" | cut -d= -f2-)
        SERVER_PASSWORD=$(grep "ServerPassword=" "$config_file" | cut -d= -f2-)
        ADMIN_PASSWORD=$(grep "ServerAdminPassword=" "$config_file" | cut -d= -f2-)
        MAX_PLAYERS=$(grep "MaxPlayers=" "$config_file" | cut -d= -f2-)
        MAP_NAME=$(grep "MapName=" "$config_file" | cut -d= -f2-)
        RCON_PORT=$(grep "RCONPort=" "$config_file" | cut -d= -f2-)
        QUERY_PORT=$(grep "QueryPort=" "$config_file" | cut -d= -f2-)
        GAME_PORT=$(grep "Port=" "$config_file" | cut -d= -f2-)
        MOD_IDS=$(grep "ModIDs=" "$config_file" | cut -d= -f2-)
        SAVE_DIR=$(grep "SaveDir=" "$config_file" | cut -d= -f2-)
        CLUSTER_ID=$(grep "ClusterID=" "$config_file" | cut -d= -f2-)
    else
        echo "Configuration file for instance $instance not found."
        return 1
    fi
}

# Function to create a new instance
create_instance() {
    echo "Enter the name for the new instance:"
    read -r instance_name
    if [ -d "$INSTANCES_DIR/$instance_name" ]; then
        echo "Instance already exists."
        return
    fi
    mkdir -p "$INSTANCES_DIR/$instance_name"
    edit_instance_config "$instance_name"
    initialize_proton_prefix "$instance_name"
    echo "Instance $instance_name created, configured, and Proton prefix initialized."
}

# Function to select an instance
select_instance() {
    list_instances
    echo "Enter the name of the instance you want to manage:"
    read -r selected_instance
    if [ ! -d "$INSTANCES_DIR/$selected_instance" ]; then
        echo "Instance does not exist."
        return 1
    fi
    return 0
}

# Function to start the server
start_server() {
    local instance=$1
    load_instance_config "$instance" || return 1

    echo "Starting server for instance: $instance"

    # Set Proton environment variables
    export STEAM_COMPAT_DATA_PATH="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$BASE_DIR"

    # Ensure per-instance Config directory exists
    local instance_config_dir="$INSTANCES_DIR/$instance/Config"
    if [ ! -d "$instance_config_dir" ]; then
        mkdir -p "$instance_config_dir"
        cp -r "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/." "$instance_config_dir/"
    fi

    # Backup the original Config directory if not already backed up
    if [ ! -L "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" ] && [ -d "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" ]; then
        mv "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer.bak"
    fi

    # Link the instance Config directory
    rm -rf "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer"
    ln -s "$instance_config_dir" "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer"

    # Ensure per-instance save directory exists
    local save_dir="$SERVER_FILES_DIR/ShooterGame/Saved/SavedArks/$SAVE_DIR"
    mkdir -p "$save_dir"

    # Set cluster parameters if ClusterID is set
    local cluster_params=""
    if [ -n "$CLUSTER_ID" ]; then
        local cluster_dir="$BASE_DIR/clusters/$CLUSTER_ID"
        mkdir -p "$cluster_dir"
        cluster_params="-ClusterDirOverride=\"$cluster_dir\" -ClusterId=\"$CLUSTER_ID\""
    fi

    # Use the loaded configuration variables here
    "$PROTON_DIR/proton" run "$SERVER_FILES_DIR/ShooterGame/Binaries/Win64/ArkAscendedServer.exe" \
        "$MAP_NAME?listen?SessionName=$SERVER_NAME?MaxPlayers=$MAX_PLAYERS?ServerPassword=$SERVER_PASSWORD?ServerAdminPassword=$ADMIN_PASSWORD?QueryPort=$QUERY_PORT?Port=$GAME_PORT?RCONEnabled=True?RCONPort=$RCON_PORT?AltSaveDirectoryName=$SAVE_DIR" \
        -NoBattlEye \
        -crossplay \
        -NoHangDetection \
        -useallavailablecores \
        -nosteamclient \
        -game \
        $cluster_params \
        -server \
        -log \
        -mods="$MOD_IDS" \
        > "$INSTANCES_DIR/$instance/server.log" 2>&1 &

    echo "Server started for instance: $instance"
}

# Function to stop the server
stop_server() {
    local instance=$1
    load_instance_config "$instance" || return 1
    echo "Stopping server for instance: $instance"
    pkill -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR"
    echo "Server stopped for instance: $instance"
}

# Function to start RCON CLI
start_rcon_cli() {
    local instance=$1
    load_instance_config "$instance" || return 1

    echo "Starting RCON CLI for instance: $instance"
    "$RCON_CLI_DIR/rcon" -a "localhost:$RCON_PORT" -p "$ADMIN_PASSWORD"
}

# Function to change map
change_map() {
    local instance=$1
    load_instance_config "$instance" || return 1

    echo "Current map: $MAP_NAME"
    echo "Enter the new map name:"
    read -r new_map_name
    sed -i "s/MapName=.*/MapName=$new_map_name/" "$INSTANCES_DIR/$instance/instance_config.ini"
    echo "Map changed to $new_map_name. Restart the server for changes to take effect."
}

# Function to change mods
change_mods() {
    local instance=$1
    load_instance_config "$instance" || return 1

    echo "Current mods: $MOD_IDS"
    echo "Enter the new mod IDs (comma-separated):"
    read -r new_mod_ids
    sed -i "s/ModIDs=.*/ModIDs=$new_mod_ids/" "$INSTANCES_DIR/$instance/instance_config.ini"
    echo "Mods changed to $new_mod_ids. Restart the server for changes to take effect."
}

# Function to check server status
check_server_status() {
    local instance=$1
    load_instance_config "$instance" || return 1
    if pgrep -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR" > /dev/null; then
        echo "Server for instance $instance is running."
    else
        echo "Server for instance $instance is not running."
    fi
}

# Function to start all instances
start_all_instances() {
    echo "Starting all server instances..."
    for instance in "$INSTANCES_DIR"/*; do
        if [ -d "$instance" ]; then
            instance_name=$(basename "$instance")
            echo "Starting instance: $instance_name"
            start_server "$instance_name"
        fi
    done
    echo "All instances have been started."
}

# Function to stop all instances
stop_all_instances() {
    echo "Stopping all server instances..."
    for instance in "$INSTANCES_DIR"/*; do
        if [ -d "$instance" ]; then
            instance_name=$(basename "$instance")
            echo "Stopping instance: $instance_name"
            stop_server "$instance_name"
        fi
    done
    echo "All instances have been stopped."
}

# Function to send RCON command
send_rcon_command() {
    local instance=$1
    local command=$2
    load_instance_config "$instance" || return 1

    echo "Sending RCON command to instance: $instance"
    "$RCON_CLI_DIR/rcon" -a "localhost:$RCON_PORT" -p "$ADMIN_PASSWORD" "$command"
}

# Function to show running instances
show_running_instances() {
    echo "Checking running instances..."
    local running_count=0
    for instance in "$INSTANCES_DIR"/*; do
        if [ -d "$instance" ]; then
            instance_name=$(basename "$instance")
            if [ -f "$INSTANCES_DIR/$instance_name/server.pid" ]; then
                pid=$(cat "$INSTANCES_DIR/$instance_name/server.pid")
                if ps -p "$pid" > /dev/null; then
                    echo -e "\e[32m$instance_name is running (PID $pid)\e[0m"
                    ((running_count++))
                fi
            fi
        fi
    done
    if [ $running_count -eq 0 ]; then
        echo "No instances are currently running."
    else
        echo "Total running instances: $running_count"
    fi
}

# Function to delete an instance
delete_instance() {
    local instance=$1
    if [ -z "$instance" ]; then
        echo "Please select an instance to delete:"
        select_instance
        instance=$selected_instance
    fi

    if [ -d "$INSTANCES_DIR/$instance" ]; then
        echo -e "\e[31mWarning: This will permanently delete the instance '$instance' and all its data.\e[0m"
        read -p "Are you sure you want to proceed? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            # Stop the instance if it's running
            if [ -f "$INSTANCES_DIR/$instance/server.pid" ]; then
                echo "Stopping instance '$instance'..."
                stop_server "$instance"
            fi

            # Remove symlink and restore original Config directory if necessary
            rm -f "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer"
            if [ -d "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer.bak" ]; then
                mv "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer.bak" "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer"
            fi

            # Delete the instance directory
            rm -rf "$INSTANCES_DIR/$instance"
            echo -e "\e[32mInstance '$instance' has been deleted.\e[0m"
        else
            echo "Deletion cancelled."
        fi
    else
        echo "Instance '$instance' does not exist."
    fi
}

# Main menu
main_menu() {
    while true; do
        echo -e "\e[38;5;214mARK Server Instance Management\e[0m"
        echo
        echo -e "\e[38;5;214m1) Install/Update Base Server\e[0m"
        echo -e "\e[38;5;214m2) List Instances\e[0m"
        echo -e "\e[38;5;214m3) Create New Instance\e[0m"
        echo -e "\e[38;5;214m4) Manage Instance\e[0m"
        echo -e "\e[38;5;214m5) Start All Instances\e[0m"
        echo -e "\e[38;5;214m6) Stop All Instances\e[0m"
        echo -e "\e[38;5;214m7) Show Running Instances\e[0m"
        echo -e "\e[38;5;214m8) Delete Instance\e[0m"
        echo -e "\e[38;5;214m9) Exit\e[0m"
        echo -e "\e[38;5;214mPlease choose an option:\e[0m"

        read -r option
        case $option in
            1)
                install_base_server
                ;;
            2)
                list_instances
                ;;
            3)
                create_instance
                ;;
            4)
                if select_instance; then
                    manage_instance "$selected_instance"
                fi
                ;;
            5)
                start_all_instances
                ;;
            6)
                stop_all_instances
                ;;
            7)
                show_running_instances
                ;;
            8)
                delete_instance
                ;;
            9)
                echo "Exiting ARK Server Manager. Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option selected."
                ;;
        esac
    done
}

# Instance management menu
manage_instance() {
    local instance=$1
    while true; do
        echo -e "\e[38;5;214mManaging Instance: $instance\e[0m"
        echo
        echo -e "\e[38;5;214m1) Start Server\e[0m"
        echo -e "\e[38;5;214m2) Stop Server\e[0m"
        echo -e "\e[38;5;214m3) Restart Server\e[0m"
        echo -e "\e[38;5;214m4) Open RCON Console\e[0m"
        echo -e "\e[38;5;214m5) Edit Configuration\e[0m"
        echo -e "\e[38;5;214m6) Change Map\e[0m"
        echo -e "\e[38;5;214m7) Change Mods\e[0m"
        echo -e "\e[38;5;214m8) Check Server Status\e[0m"
        echo -e "\e[38;5;214m9) Back to Main Menu\e[0m"
        echo -e "\e[38;5;214mPlease choose an option:\e[0m"

        read -r option
        case $option in
            1)
                start_server "$instance"
                ;;
            2)
                stop_server "$instance"
                ;;
            3)
                stop_server "$instance"
                start_server "$instance"
                ;;
            4)
                start_rcon_cli "$instance"
                ;;
            5)
                edit_instance_config "$instance"
                ;;
            6)
                change_map "$instance"
                ;;
            7)
                change_mods "$instance"
                ;;
            8)
                check_server_status "$instance"
                ;;
            9)
                return
                ;;
            *)
                echo "Invalid option selected."
                ;;
        esac
    done
}

# Main script execution
if [ $# -eq 0 ]; then
    main_menu
else
    case $1 in
        update)
            install_base_server
            ;;
        start_all)
            start_all_instances
            ;;
        stop_all)
            stop_all_instances
            ;;
        show_running)
            show_running_instances
            ;;
        delete)
            if [ -z "$2" ]; then
                echo "Usage: $0 delete <instance_name>"
                exit 1
            fi
            delete_instance "$2"
            ;;
        *)
            instance_name=$1
            action=$2
            case $action in
                start)
                    start_server "$instance_name"
                    ;;
                stop)
                    stop_server "$instance_name"
                    ;;
                restart)
                    stop_server "$instance_name"
                    start_server "$instance_name"
                    ;;
                send_rcon)
                    if [ $# -lt 3 ]; then
                        echo "Usage: $0 <instance_name> send_rcon \"<rcon_command>\""
                        exit 1
                    fi
                    rcon_command="${@:3}"  # Get all arguments from the third onwards
                    send_rcon_command "$instance_name" "$rcon_command"
                    ;;
                *)
                    echo "Usage: $0 [update|start_all|stop_all|show_running|delete <instance_name>]"
                    echo "       $0 <instance_name> [start|stop|restart|send_rcon \"<rcon_command>\"]"
                    echo "Or run without arguments to enter interactive mode."
                    exit 1
                    ;;
            esac
            ;;
    esac
fi
