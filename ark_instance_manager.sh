#!/bin/bash

export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

set -e

# Color definitions
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

# Signal handling to inform the user and kill processes
trap 'echo -e "${RED}Script interrupted. Servers that have already started will continue running.${RESET}"; pkill -P $$; exit 1' SIGINT SIGTERM

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

# Define URLs for SteamCMD, Proton, and RCON CLI
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$PROTON_VERSION/$PROTON_VERSION.tar.gz"
RCONCLI_URL="https://github.com/gorcon/rcon-cli/releases/download/v$RCONCLI_VERSION/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz"

check_dependencies() {
    local missing=()
    local package_manager=""
    local dependencies=()
    local config_file="$BASE_DIR/.ark_server_manager_config"

    # Detect the package manager
    if command -v apt-get >/dev/null 2>&1; then
        package_manager="apt-get"
        dependencies=("wget" "tar" "grep" "libc6:i386" "libstdc++6:i386" "libncursesw6:i386" "python3" "libfreetype6:i386" "libfreetype6:amd64" "pkill")
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
        dependencies=("wget" "tar" "grep" "libX11-6-32bit" "libX11-devel-32bit" "gcc-32bit" "libexpat1-32bit" "libXext6-32bit" "python3" "pkill" "libfreetype6" "libfreetype6-32bit")
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
        dependencies=("wget" "tar" "grep" "glibc-devel.i686" "ncurses-devel.i686" "libstdc++-devel.i686" "python3" "freetype" "procps-ng")
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
        dependencies=("wget" "tar" "grep" "lib32-libx11" "gcc-multilib" "lib32-expat" "lib32-libxext" "python" "freetype2")
    else
        echo -e "${RED}Error: No supported package manager found on this system.${RESET}"
        exit 1
    fi

    # Check for missing dependencies
    for cmd in "${dependencies[@]}"; do
        if [ "$package_manager" == "apt-get" ] && [[ "$cmd" == *:i386* || "$cmd" == *:amd64* ]]; then
            if ! dpkg-query -W -f='${Status}' "$cmd" 2>/dev/null | grep -q "install ok installed"; then
                missing+=("$cmd")
            fi
        elif [ "$package_manager" == "zypper" ]; then
            if ! rpm -q "${cmd}" >/dev/null 2>&1 && ! command -v "${cmd}" >/dev/null 2>&1; then
                missing+=("$cmd")
            fi
        elif [ "$package_manager" == "dnf" ]; then
            if ! rpm -q "${cmd}" >/dev/null 2>&1 && ! command -v "${cmd}" >/dev/null 2>&1; then
                missing+=("$cmd")
            fi
        elif [ "$package_manager" == "pacman" ]; then
            if ! pacman -Qi "${cmd}" >/dev/null 2>&1 && ! ldconfig -p | grep -q "${cmd}"; then
                missing+=("$cmd")
            fi
        elif [ "$cmd" == "pkill" ]; then
            if ! command -v pkill >/dev/null 2>&1; then
                missing+=("procps")
            fi
        else
            if ! command -v "${cmd}" >/dev/null 2>&1; then
                missing+=("$cmd")
            fi
        fi
    done

    # Report missing dependencies and ask to continue
    if [ ${#missing[@]} -ne 0 ]; then
        # Check if the user has chosen to suppress warnings
        if [ -f "$config_file" ] && grep -q "SUPPRESS_DEPENDENCY_WARNINGS=true" "$config_file"; then
            echo -e "${YELLOW}Continuing despite missing dependencies (warnings suppressed)...${RESET}"
            return
        fi

        echo -e "${RED}Warning: The following required packages are missing: ${missing[*]}${RESET}"
        echo -e "${CYAN}Please install them using the appropriate command for your system:${RESET}"
        case $package_manager in
            "apt-get")
                echo -e "${MAGENTA}sudo dpkg --add-architecture i386${RESET}"
                echo -e "${MAGENTA}sudo apt update${RESET}"
                echo -e "${MAGENTA}sudo apt-get install ${YELLOW}${missing[*]}${RESET}"
                ;;
            "zypper")
                echo -e "${MAGENTA}sudo zypper install ${YELLOW}${missing[*]}${RESET}"
                ;;
            "dnf")
                echo -e "${MAGENTA}sudo dnf install ${YELLOW}${missing[*]}${RESET}"
                ;;
            "pacman")
                echo -e "${BLUE}For Arch Linux users:${RESET}"
                echo -e "${CYAN}1. Edit the pacman configuration file:${RESET}"
                echo -e "   ${MAGENTA}sudo nano /etc/pacman.conf${RESET}"
                echo
                echo -e "${CYAN}2. Find and uncomment the following lines to enable the multilib repository:${RESET}"
                echo -e "   ${GREEN}[multilib]${RESET}"
                echo -e "   ${GREEN}Include = /etc/pacman.d/mirrorlist${RESET}"
                echo
                echo -e "${CYAN}3. Save the file and exit the editor${RESET}"
                echo
                echo -e "${CYAN}4. Update the package database:${RESET}"
                echo -e "   ${MAGENTA}sudo pacman -Sy${RESET}"
                echo
                echo -e "${CYAN}5. Install the missing packages:${RESET}"
                echo -e "   ${MAGENTA}sudo pacman -S ${YELLOW}${missing[*]}${RESET}"
                ;;
        esac

        echo -e "\n"
        echo -e "${YELLOW}Continue anyway?${RESET} ${RED}(not recommended)${RESET} ${YELLOW}[y/N]${RESET}"
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            echo -e "${RED}Exiting due to missing dependencies.${RESET}"
            exit 1
        fi

        echo
        echo -e "${YELLOW}Do you want to suppress this warning in the future? [y/N]${RESET}"
        read -r suppress_response
        if [[ $suppress_response =~ ^[Yy]$ ]]; then
            echo "SUPPRESS_DEPENDENCY_WARNINGS=true" >> "$config_file"
            echo -e "${GREEN}Dependency warnings will be suppressed in future runs.${RESET}"
        fi

        echo -e "${YELLOW}Continuing despite missing dependencies...${RESET}"
    fi
}

# Check dependencies before proceeding
check_dependencies

# Function to check if a server is running
is_server_running() {
    local instance=$1
    load_instance_config "$instance" || return 1
    if pgrep -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to install or update the base server
install_base_server() {
    echo -e "${CYAN}Installing/updating base server...${RESET}"

    # Create necessary directories
    mkdir -p "$STEAMCMD_DIR" "$PROTON_DIR" "$RCON_CLI_DIR" "$SERVER_FILES_DIR"

    # Download and unpack SteamCMD if not already installed
    if [ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]; then
        echo -e "${CYAN}Downloading SteamCMD...${RESET}"
        wget -q -O "$STEAMCMD_DIR/steamcmd_linux.tar.gz" "$STEAMCMD_URL"
        tar -xzf "$STEAMCMD_DIR/steamcmd_linux.tar.gz" -C "$STEAMCMD_DIR"
        rm "$STEAMCMD_DIR/steamcmd_linux.tar.gz"
    else
        echo -e "${GREEN}SteamCMD already installed.${RESET}"
    fi

    # Download and unpack Proton if not already installed
    if [ ! -d "$PROTON_DIR/files" ]; then
        echo -e "${CYAN}Downloading Proton...${RESET}"
        wget -q -O "$PROTON_DIR/$PROTON_VERSION.tar.gz" "$PROTON_URL"
        tar -xzf "$PROTON_DIR/$PROTON_VERSION.tar.gz" -C "$PROTON_DIR" --strip-components=1
        rm "$PROTON_DIR/$PROTON_VERSION.tar.gz"
    else
        echo -e "${GREEN}Proton already installed.${RESET}"
    fi

    # Download and unpack RCON CLI if not already installed
    if [ ! -f "$RCON_CLI_DIR/rcon" ]; then
        echo -e "${CYAN}Downloading RCON CLI...${RESET}"
        wget -q -O "$RCON_CLI_DIR/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz" "$RCONCLI_URL"
        tar -xzf "$RCON_CLI_DIR/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz" -C "$RCON_CLI_DIR" --strip-components=1
        rm "$RCON_CLI_DIR/rcon-$RCONCLI_VERSION-amd64_linux.tar.gz"
    else
        echo -e "${GREEN}RCON CLI already installed.${RESET}"
    fi

    # Install or update ARK server using SteamCMD
    echo -e "${CYAN}Installing/updating ARK server...${RESET}"
    "$STEAMCMD_DIR/steamcmd.sh" +force_install_dir "$SERVER_FILES_DIR" +login anonymous +app_update 2430930 validate +quit

    # Check if configuration directory exists
    if [ ! -d "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/" ]; then
        echo -e "${CYAN}First installation detected. Initializing Proton prefix...${RESET}"

        # Set Proton environment variables
        export STEAM_COMPAT_DATA_PATH="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
        export STEAM_COMPAT_CLIENT_INSTALL_PATH="$BASE_DIR"

        # Initialize Proton prefix
        initialize_proton_prefix

        echo -e "${CYAN}Starting server once to generate configuration files... This will take 60 seconds${RESET}"

        # Initial server start to generate configs
        "$PROTON_DIR/proton" run "$SERVER_FILES_DIR/ShooterGame/Binaries/Win64/ArkAscendedServer.exe" \
            "TheIsland_WP?listen" \
            -NoBattlEye \
            -crossplay \
            -server \
            -log \
            -nosteamclient \
            -game &
        # Wait to generate files
        sleep 60
        # Stop the server
        pkill -f "ArkAscendedServer.exe.*TheIsland_WP" || true
        echo -e "${GREEN}Initial server start completed.${RESET}"
    else
        echo -e "${GREEN}Server configuration directory already exists. Skipping initial server start.${RESET}"
    fi

    echo -e "${GREEN}Base server installation/update completed.${RESET}"
}

# Function to initialize Proton prefix
initialize_proton_prefix() {
    local proton_prefix="$SERVER_FILES_DIR/steamapps/compatdata/2430930"

    # Ensure the directory exists
    mkdir -p "$proton_prefix"

    # Copy the default Proton prefix
    cp -r "$PROTON_DIR/files/share/default_pfx/." "$proton_prefix/"

    echo -e "${GREEN}Proton prefix initialized.${RESET}"
}

# Function to list all instances
list_instances() {
    echo -e "${YELLOW}Available instances:${RESET}"
    ls -1 "$INSTANCES_DIR" 2>/dev/null || echo -e "${RED}No instances found.${RESET}"
}

# Function to create or edit instance configuration
edit_instance_config() {
    local instance=$1
    local config_file="$INSTANCES_DIR/$instance/instance_config.ini"
    local game_ini_file="$INSTANCES_DIR/$instance/Config/Game.ini"

    # Create instance directory if it doesn't exist
    if [ ! -d "$INSTANCES_DIR/$instance" ]; then
        mkdir -p "$INSTANCES_DIR/$instance"
    fi

      # Create the Config directory if it doesn't exist
    if [ ! -d "$INSTANCES_DIR/$instance/Config" ]; then
        mkdir -p "$INSTANCES_DIR/$instance/Config"
    fi

    # Create config file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        cat <<EOF > "$config_file"
[ServerSettings]
ServerName=ARK Server $instance
ServerPassword=
ServerAdminPassword=adminpassword
MaxPlayers=70
MapName=TheIsland_WP
RCONPort=27020
QueryPort=27015
Port=7777
ModIDs=
SaveDir=$instance
ClusterID=
EOF
        chmod 600 "$config_file"  # Set file permissions to be owner-readable and writable
    fi

     # Create an empty Game.ini, if it doesnt exist
    if [ ! -f "$game_ini_file" ]; then
        touch "$game_ini_file"
        echo -e "${GREEN}Empty Game.ini for '$instance' Created. Optional: Edit it for your needs${RESET}"
    fi

    # Open the config file in the default text editor
    if [ -n "$EDITOR" ]; then
        "$EDITOR" "$config_file"
    elif command -v nano >/dev/null 2>&1; then
        nano "$config_file"
    elif command -v vim >/dev/null 2>&1; then
        vim "$config_file"
    else
        echo -e "${RED}No suitable text editor found. Please edit $config_file manually.${RESET}"
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
        echo -e "${RED}Configuration file for instance $instance not found.${RESET}"
        return 1
    fi
}

# Function to create a new instance (using 'read' with validation)
create_instance() {
    # Check if the directory exists
    if [ ! -d "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/" ]; then
        echo -e "${RED}The required directory does not exist: $SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/${RESET}"
        echo -e "${YELLOW}Cannot proceed with instance creation.You need to install Base Server first${RESET}"
        return
    fi

    while true; do
        echo -e "${CYAN}Enter the name for the new instance (or type 'cancel' to abort):${RESET}"
        read -r instance_name
        if [ "$instance_name" = "cancel" ]; then
            echo -e "${YELLOW}Instance creation cancelled.${RESET}"
            return
        elif [ -z "$instance_name" ]; then
            echo -e "${RED}Instance name cannot be empty.${RESET}"
        elif [ -d "$INSTANCES_DIR/$instance_name" ]; then
            echo -e "${RED}Instance already exists.${RESET}"
        else
            mkdir -p "$INSTANCES_DIR/$instance_name"
            edit_instance_config "$instance_name"
            initialize_proton_prefix "$instance_name"
            echo -e "${GREEN}Instance $instance_name created and configured.${RESET}"
            return
        fi
    done
}

# Function to select an instance using 'select'
select_instance() {
    local instances=()
    local i=1

    # Populate the instances array
    for dir in "$INSTANCES_DIR"/*; do
        if [ -d "$dir" ]; then
            instances+=("$(basename "$dir")")
        fi
    done

    if [ ${#instances[@]} -eq 0 ]; then
        echo -e "${RED}No instances found.${RESET}"
        return 1
    fi

    echo -e "${YELLOW}Available instances:${RESET}"
    PS3="Please select an instance: "
    select selected_instance in "${instances[@]}" "Cancel"; do
        if [ "$REPLY" -gt 0 ] && [ "$REPLY" -le "${#instances[@]}" ]; then
            echo -e "${GREEN}You have selected: $selected_instance${RESET}"
            return 0
        elif [ "$REPLY" -eq $((${#instances[@]} + 1)) ]; then
            echo -e "${YELLOW}Operation cancelled.${RESET}"
            return 1
        else
            echo -e "${RED}Invalid selection.${RESET}"
        fi
    done
}

# Function to start the server
start_server() {
    local instance=$1
    if is_server_running "$instance"; then
        echo -e "${YELLOW}Server for instance $instance is already running.${RESET}"
        return 0
    fi

    load_instance_config "$instance" || return 1

    echo -e "${CYAN}Starting server for instance: $instance${RESET}"

    # Set Proton environment variables
    export STEAM_COMPAT_DATA_PATH="$SERVER_FILES_DIR/steamapps/compatdata/2430930"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$BASE_DIR"

    # Ensure per-instance Config directory exists
    local instance_config_dir="$INSTANCES_DIR/$instance/Config"
    if [ ! -d "$instance_config_dir" ]; then
        mkdir -p "$instance_config_dir"
        cp -r "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer/." "$instance_config_dir/" || true
        # Set permissions for GameUserSettings.ini
        chmod 600 "$instance_config_dir/GameUserSettings.ini" || true
    fi

    # Backup the original Config directory if not already backed up
    if [ ! -L "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" ] && [ -d "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" ]; then
        mv "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer.bak" || true
    fi

    # Link the instance Config directory
    rm -rf "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" || true
    ln -s "$instance_config_dir" "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" || true

    # Ensure per-instance save directory exists
    local save_dir="$SERVER_FILES_DIR/ShooterGame/Saved/SavedArks/$SAVE_DIR"
    mkdir -p "$save_dir" || true

    # Set cluster parameters if ClusterID is set
    local cluster_params=""
    if [ -n "$CLUSTER_ID" ]; then
        local cluster_dir="$BASE_DIR/clusters/$CLUSTER_ID"
        mkdir -p "$cluster_dir" || true
        cluster_params="-ClusterDirOverride=\"$cluster_dir\" -ClusterId=\"$CLUSTER_ID\""
    fi

    # Start the server using the loaded configuration variables
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

    echo -e "${GREEN}Server started for instance: $instance. It should be fully operational in approximately 60 seconds.${RESET}"
}

# Function to stop the server
stop_server() {
    local instance=$1
    if ! is_server_running "$instance"; then
        echo -e "${YELLOW}Server for instance $instance is not running.${RESET}"
        return 0
    fi

    load_instance_config "$instance" || return 1
    echo -e "${CYAN}Stopping server for instance: $instance${RESET}"
    pkill -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR" || true
    echo -e "${GREEN}Server stopped for instance: $instance${RESET}"
}

# Function to start RCON CLI
start_rcon_cli() {
    local instance=$1
        if ! is_server_running "$instance"; then
        echo -e "${YELLOW}Server for instance $instance is not running.${RESET}"
        return 0
    fi

    load_instance_config "$instance" || return 1

    echo -e "${CYAN}Starting RCON CLI for instance: $instance${RESET}"
    "$RCON_CLI_DIR/rcon" -a "localhost:$RCON_PORT" -p "$ADMIN_PASSWORD" || true
}

# Function to change map
change_map() {
    local instance=$1
    load_instance_config "$instance" || return 1
    echo -e "${CYAN}Current map: $MAP_NAME${RESET}"
    echo -e "${CYAN}Enter the new map name (or type 'cancel' to abort):${RESET}"
    read -r new_map_name
    if [[ "$new_map_name" == "cancel" ]]; then
        echo -e "${YELLOW}Map change aborted.${RESET}"
        return 0
    fi
    sed -i "s/MapName=.*/MapName=$new_map_name/" "$INSTANCES_DIR/$instance/instance_config.ini"
    echo -e "${GREEN}Map changed to $new_map_name. Restart the server for changes to take effect.${RESET}"
}

# Function to change mods
change_mods() {
    local instance=$1
    load_instance_config "$instance" || return 1
    echo -e "${CYAN}Current mods: $MOD_IDS${RESET}"
    echo -e "${CYAN}Enter the new mod IDs (comma-separated, or type 'cancel' to abort):${RESET}"
    read -r new_mod_ids
    if [[ "$new_mod_ids" == "cancel" ]]; then
        echo -e "${YELLOW}Mod change aborted.${RESET}"
        return 0
    fi
    sed -i "s/ModIDs=.*/ModIDs=$new_mod_ids/" "$INSTANCES_DIR/$instance/instance_config.ini"
    echo -e "${GREEN}Mods changed to $new_mod_ids. Restart the server for changes to take effect.${RESET}"
}

# Function to check server status
check_server_status() {
    local instance=$1
    load_instance_config "$instance" || return 1
    if pgrep -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR" > /dev/null; then
        echo -e "${GREEN}Server for instance $instance is running.${RESET}"
    else
        echo -e "${RED}Server for instance $instance is not running.${RESET}"
    fi
}

# Function to start all instances with a delay between each
start_all_instances() {
    echo -e "${CYAN}Starting all server instances...${RESET}"
    for instance in "$INSTANCES_DIR"/*; do
        if [ -d "$instance" ]; then
            instance_name=$(basename "$instance")
            if is_server_running "$instance_name"; then
                echo -e "${YELLOW}Instance $instance_name is already running. Skipping...${RESET}"
                continue
            fi
            echo -e "${CYAN}Starting instance: $instance_name${RESET}"
            start_server "$instance_name"
            # Waiting 30 seconds before starting the next instance
            echo -e "${YELLOW}Waiting 30 seconds before starting the next instance...${RESET}"
            sleep 30
        fi
    done
    echo -e "${GREEN}All instances have been started.${RESET}"
}

# Function to stop all instances
stop_all_instances() {
    echo -e "${CYAN}Stopping all server instances...${RESET}"
    for instance in "$INSTANCES_DIR"/*; do
        if [ -d "$instance" ]; then
            instance_name=$(basename "$instance")
            if ! is_server_running "$instance_name"; then
                echo -e "${YELLOW}Instance $instance_name is not running. Skipping...${RESET}"
                continue
            fi
            echo -e "${CYAN}Stopping instance: $instance_name${RESET}"
            stop_server "$instance_name"
        fi
    done
    echo -e "${GREEN}All instances have been stopped.${RESET}"
}

# Function to send RCON command
send_rcon_command() {
    local instance=$1
    local command=$2
    if ! is_server_running "$instance"; then
        echo -e "${YELLOW}Server for instance $instance is not running. Cannot send RCON command.${RESET}"
        return 1
    fi

    load_instance_config "$instance" || return 1

    echo -e "${CYAN}Sending RCON command to instance: $instance${RESET}"
    "$RCON_CLI_DIR/rcon" -a "localhost:$RCON_PORT" -p "$ADMIN_PASSWORD" "$command" || true
}

# Function to show running instances
show_running_instances() {
    echo -e "${CYAN}Checking running instances...${RESET}"
    local running_count=0
    for instance in "$INSTANCES_DIR"/*; do
        if [ -d "$instance" ]; then
            instance_name=$(basename "$instance")
            # Load instance configuration
            load_instance_config "$instance_name" || continue
            # Check if the server is running
            if pgrep -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR" > /dev/null; then
                echo -e "${GREEN}$instance_name is running${RESET}"
                ((running_count++)) || true
            else
                echo -e "${RED}$instance_name is not running${RESET}"
            fi
        fi
    done
    if [ $running_count -eq 0 ]; then
        echo -e "${RED}No instances are currently running.${RESET}"
    else
        echo -e "${GREEN}Total running instances: $running_count${RESET}"
    fi
}

# Function to delete an instance
delete_instance() {
    local instance=$1
    if [ -z "$instance" ]; then
        if ! select_instance; then
            return
        fi
        instance=$selected_instance
    fi
    if [ -d "$INSTANCES_DIR/$instance" ]; then
        echo -e "${RED}Warning: This will permanently delete the instance '$instance' and all its data.${RESET}"
        echo "Type CONFIRM to delete the instance '$instance', or cancel to abort"
        read -p "> " response

        if [[ $response == "CONFIRM" ]]; then
            # Load instance config
            load_instance_config "$instance"
            # Stop instance if it's running
            if pgrep -f "ArkAscendedServer.exe.*AltSaveDirectoryName=$SAVE_DIR" > /dev/null; then
                echo -e "${CYAN}Stopping instance '$instance'...${RESET}"
                stop_server "$instance"
            fi
            # Check if other instances are running
            if pgrep -f "ArkAscendedServer.exe" > /dev/null; then
                echo -e "${YELLOW}Other instances are still running. Not removing the Config symlink to avoid affecting other servers.${RESET}"
            else
                # Remove the symlink and restore the original configuration directory
                rm -f "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" || true
                if [ -d "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer.bak" ]; then
                    mv "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer.bak" "$SERVER_FILES_DIR/ShooterGame/Saved/Config/WindowsServer" || true
                fi
            fi
            # Deleting the instance directory and save games
            rm -rf "$INSTANCES_DIR/$instance" || true
            rm -rf "$SERVER_FILES_DIR/ShooterGame/Saved/$instance" || true
            rm -rf "$SERVER_FILES_DIR/ShooterGame/Saved/SavedArks/$instance" || true
            echo -e "${GREEN}Instance '$instance' has been deleted.${RESET}"
        elif [[ $response == "cancel" ]]; then
            echo -e "${YELLOW}Deletion cancelled.${RESET}"
        else
            echo -e "${YELLOW}Invalid response. Deletion cancelled.${RESET}"
        fi
    else
        echo -e "${RED}Instance '$instance' does not exist.${RESET}"
    fi
}

# Function to change instance name
change_instance_name() {
    local instance=$1
    load_instance_config "$instance" || return 1

    echo -e "${CYAN}Enter the new name for instance '$instance' (or type 'cancel' to abort):${RESET}"
    read -r new_instance_name

    # Validation
    if [ "$new_instance_name" = "cancel" ]; then
        echo -e "${YELLOW}Instance renaming cancelled.${RESET}"
        return
    elif [ -z "$new_instance_name" ]; then
        echo -e "${RED}Instance name cannot be empty.${RESET}"
        return 1
    elif [ -d "$INSTANCES_DIR/$new_instance_name" ]; then
        echo -e "${RED}An instance with the name '$new_instance_name' already exists.${RESET}"
        return 1
    fi

    # Stop the server if running
    if is_server_running "$instance"; then
        echo -e "${CYAN}Stopping running server for instance '$instance' before renaming...${RESET}"
        stop_server "$instance"
    fi

    # Rename instance directory
    mv "$INSTANCES_DIR/$instance" "$INSTANCES_DIR/$new_instance_name" || {
        echo -e "${RED}Failed to rename instance directory.${RESET}"
        return 1
    }

    # Rename save directories if they exist
    if [ -d "$SERVER_FILES_DIR/ShooterGame/Saved/$instance" ]; then
        mv "$SERVER_FILES_DIR/ShooterGame/Saved/$instance" "$SERVER_FILES_DIR/ShooterGame/Saved/$new_instance_name" || true
    fi

    if [ -d "$SERVER_FILES_DIR/ShooterGame/Saved/SavedArks/$instance" ]; then
        mv "$SERVER_FILES_DIR/ShooterGame/Saved/SavedArks/$instance" "$SERVER_FILES_DIR/ShooterGame/Saved/SavedArks/$new_instance_name" || true
    fi

    # Update SaveDir in the instance configuration
    sed -i "s/^SaveDir=.*/SaveDir=$new_instance_name/" "$INSTANCES_DIR/$new_instance_name/instance_config.ini"

    echo -e "${GREEN}Instance renamed from '$instance' to '$new_instance_name'.${RESET}"
}

# Function to edit GameUserSettins.ini
edit_gameusersettings() {
    local instance=$1
    local file_path="$INSTANCES_DIR/$instance/Config/GameUserSettings.ini"

    #Check if server is running
    if is_server_running "$instance"; then
        echo -e "${YELLOW}Server for instance $instance is running. Stop it to edit config${RESET}"
        return 0
    fi
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}Error: No GameUserSettings.ini found. Start the server once to generate one or place your own in the instances/$instance/Config folder.${RESET}"
        return
    fi
    select_editor "$file_path"
}

# Function to edit Game.ini
edit_game_ini() {
    local instance=$1
    local file_path="$INSTANCES_DIR/$instance/Config/Game.ini"

    #Check if server is running
    if is_server_running "$instance"; then
        echo -e "${YELLOW}Server for instance $instance is running. Stop it to edit config${RESET}"
        return 0
    fi
    if [ ! -f "$file_path" ]; then
        echo -e "${YELLOW}Game.ini not found for instance '$instance'. Creating a new one.${RESET}"
        touch "$file_path"
    fi
    select_editor "$file_path"
}

#Function to select editor and open a file in editor
select_editor() {
local file_path="$1"

# Open the file in the default text editor
    if [ -n "$EDITOR" ]; then
        "$EDITOR" "$file_path"
    elif command -v nano >/dev/null 2>&1; then
        nano "$file_path"
    elif command -v vim >/dev/null 2>&1; then
        vim "$file_path"
    else
        echo -e "${RED}No suitable text editor found. Please edit $file_path manually.${RESET}"
    fi
}

# Menu to edit configuration files
edit_configuration_menu() {
    local instance=$1
    echo -e "${CYAN}Choose configuration to edit:${RESET}"
    options=(
        "Instance Configuration"
        "GameUserSettings.ini"
        "Game.ini"
        "Back"
    )
    PS3="Please select an option: "
    select opt in "${options[@]}"; do
        case "$REPLY" in
            1)
                edit_instance_config "$instance"
                break
                ;;
            2)
                edit_gameusersettings "$instance"
                break
                ;;
            3)
                edit_game_ini "$instance"
                break
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Invalid option selected.${RESET}"
                ;;
        esac
    done
}


# Main menu using 'select'
main_menu() {
    while true; do
        echo -e "${YELLOW}ARK Server Instance Management${RESET}"
        echo

        options=(
            "Install/Update Base Server"
            "List Instances"
            "Create New Instance"
            "Manage Instance"
            "Start All Instances"
            "Stop All Instances"
            "Show Running Instances"
            "Delete Instance"
            "Change Instance Name"
            "Exit"
        )

        PS3="Please choose an option: "
        select opt in "${options[@]}"; do
            case "$REPLY" in
                1)
                    install_base_server
                    break
                    ;;
                2)
                    list_instances
                    break
                    ;;
                3)
                    create_instance
                    break
                    ;;
                4)
                    if select_instance; then
                        manage_instance "$selected_instance"
                    fi
                    break
                    ;;
                5)
                    start_all_instances
                    break
                    ;;
                6)
                    stop_all_instances
                    break
                    ;;
                7)
                    show_running_instances
                    break
                    ;;
                8)
                    if select_instance; then
                        delete_instance "$selected_instance"
                    fi
                    break
                    ;;
                9)
                    if select_instance; then
                        change_instance_name "$selected_instance"
                    fi
                    break
                    ;;
                10)
                    echo -e "${GREEN}Exiting ARK Server Manager. Goodbye!${RESET}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Invalid option selected.${RESET}"
                    ;;
            esac
        done
    done
}

# Instance management menu using 'select'
manage_instance() {
    local instance=$1
    while true; do
        echo -e "${YELLOW}Managing Instance: $instance${RESET}"
        echo

        options=(
            "Start Server"
            "Stop Server"
            "Restart Server"
            "Open RCON Console"
            "Edit Configuration"
            "Change Map"
            "Change Mods"
            "Check Server Status"
            "Change Instance Name"
            "Back to Main Menu"
        )

        PS3="Please choose an option: "
        select opt in "${options[@]}"; do
            case "$REPLY" in
                1)
                    start_server "$instance"
                    break
                    ;;
                2)
                    stop_server "$instance"
                    break
                    ;;
                3)
                    stop_server "$instance"
                    start_server "$instance"
                    break
                    ;;
                4)
                    start_rcon_cli "$instance"
                    break
                    ;;
                5)
                    edit_configuration_menu "$instance"
                    break
                    ;;
                6)
                    change_map "$instance"
                    break
                    ;;
                7)
                    change_mods "$instance"
                    break
                    ;;
                8)
                    check_server_status "$instance"
                    break
                    ;;
                9)
                    change_instance_name "$instance"
                    instance=$new_instance_name  # Update the instance variable
                    break
                    ;;
                10)
                    return
                    ;;
                *)
                    echo -e "${RED}Invalid option selected.${RESET}"
                    ;;
            esac
        done
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
                echo -e "${RED}Usage: $0 delete <instance_name>${RESET}"
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
                        echo -e "${RED}Usage: $0 <instance_name> send_rcon \"<rcon_command>\"${RESET}"
                        exit 1
                    fi
                    rcon_command="${@:3}"  # Get all arguments from the third onwards
                    send_rcon_command "$instance_name" "$rcon_command"
                    ;;
                *)
                    echo -e "${RED}Usage: $0 [update|start_all|stop_all|show_running|delete <instance_name>]${RESET}"
                    echo -e "${RED}       $0 <instance_name> [start|stop|restart|send_rcon \"<rcon_command>\"]${RESET}"
                    echo "Or run without arguments to enter interactive mode."
                    exit 1
                    ;;
            esac
            ;;
    esac
fi
