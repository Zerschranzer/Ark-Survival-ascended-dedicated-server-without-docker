# ARK: Survival Ascended Linux Server Manager

Welcome to the comprehensive guide for installing and managing ARK: Survival Ascended servers on Linux. This tool, `ark_instance_manager.sh`, allows you to download, install, and manage multiple ARK servers on Linux—despite the lack of a native ARK: Survival Ascended server for Linux. This script offers a flexible and user-friendly solution without relying on Docker.

## Features

- Automatic dependency checking
- Multi-instance server management
- Interactive menu for easy server administration
- Command-line interface for automation and remote management
- Automatic installation of SteamCMD, Proton, and RCON CLI
- Support for custom maps and mods
- Cluster support for multi-server setups
- Colored output for improved readability
- RCON integration for server commands

## System Requirements

- A Linux system with one of the following package managers:
  - apt-get (Debian/Ubuntu)
  - zypper (OpenSUSE)
  - dnf (Fedora)
  - pacman (Arch Linux)
- Sudo rights or root access
- Sufficient disk space for ARK server files and instances

## Installation and Setup

1. Download the script:
   ```bash
   wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/ark_instance_manager.sh
   ```

2. Make it executable:
   ```bash
   chmod +x ark_instance_manager.sh
   ```

3. Run the script to install the base server:
   ```bash
   ./ark_instance_manager.sh
   ```

4. Choose "Install/Update Base Server" from the main menu to download and set up the ARK server files. This function serves to install the server as well as update it to always be up to date. It's crucial to run this before creating any instances to ensure all necessary files are present for starting server instances.

**Important:** You must install the base server before creating instances. This ensures that all necessary files are present to start server instances.

## Usage

### Interactive Mode

Run the script without arguments to enter interactive mode:

```bash
./ark_instance_manager.sh
```

This mode provides a user-friendly menu for all server management tasks.

### Command-Line Mode

The script supports various command-line arguments for quick actions and automation:

- Update or install base server:
  ```bash
  ./ark_instance_manager.sh update
  ```

- Start all instances:
  ```bash
  ./ark_instance_manager.sh start_all
  ```

- Stop all instances:
  ```bash
  ./ark_instance_manager.sh stop_all
  ```

- Show running instances:
  ```bash
  ./ark_instance_manager.sh show_running
  ```

- Delete an instance:
  ```bash
  ./ark_instance_manager.sh delete <instance_name>
  ```

- Manage a specific instance:
  ```bash
  ./ark_instance_manager.sh <instance_name> [start|stop|restart|send_rcon "<rcon_command>"]
  ```

## Server Management

### Creating a New Instance

1. From the main menu, select "Create New Instance"
2. Enter a unique name for the instance
3. Edit the instance configuration file in your default text editor

### Instance Configuration

Each instance has its own configuration file (`instance_config.ini`) with the following settings:

- ServerName
- ServerPassword
- ServerAdminPassword
- MaxPlayers
- MapName
- RCONPort
- QueryPort
- Port
- ModIDs
- SaveDir
- ClusterID

### Starting and Stopping Servers

- Use the "Start Server" and "Stop Server" options in the instance management menu
- Or use command-line arguments for quick actions:
  ```bash
  ./ark_instance_manager.sh <instance_name> start
  ./ark_instance_manager.sh <instance_name> stop
  ```

### Changing Maps and Mods

Use the instance management menu to change maps or modify the list of active mods for each instance.

### RCON Console

Access the RCON console for an instance to send commands directly to the server:

```bash
./ark_instance_manager.sh <instance_name> send_rcon "<rcon_command>"
```

## Cluster Management

To set up a cluster of servers:

1. Create multiple instances
2. Set the same `ClusterID` in the `instance_config.ini` for each instance in the cluster
3. Start the instances

The script will automatically set up the necessary cluster directory and configuration.

## Using the Restart Manager

The Restart Manager (`ark_restart_manager.sh`) is a separate script that manages automated restarts and updates for your ARK servers. Here's how to use it:

1. Download the Restart Manager script:
   ```bash
   wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/ark_restart_manager.sh
   ```

2. Make it executable:
   ```bash
   chmod +x ark_restart_manager.sh
   ```

3. Edit the script to customize your instances and announcement times:
   ```bash
   nano ark_restart_manager.sh
   ```

   Configure the following variables:
   - `instances`: List of your server instances
   - `announcement_times`: Times for restart announcements (in seconds before restart)
   - `announcement_messages`: Messages for each announcement time
   - `save_wait_time`: Wait time after saving the world
   - `start_wait_time`: Wait time between starting instances

4. Set up a cron job to run the Restart Manager regularly:
   ```bash
   crontab -e
   ```
   
   Add a line like this to run the Restart Manager daily at 4:00 AM:
   ```
   0 4 * * * /path/to/ark_restart_manager.sh
   ```

The Restart Manager performs the following actions:
1. Announces the upcoming restart
2. Saves the game world for each instance
3. Stops all server instances
4. Updates the server
5. Restarts all server instances

## Troubleshooting

- Check the server logs in the instance directory: `instances/<instance_name>/server.log`
- Ensure all dependencies are correctly installed
- Verify that the required ports are open in your firewall

## Credits

This project makes use of the following open-source tools:
- [rcon-cli](https://github.com/gorcon/rcon-cli) for remote console management.
- [Proton GE Custom](https://github.com/GloriousEggroll/proton-ge-custom) for running Windows applications on Linux.
A big thanks to the developers of these tools who make my server manager possible!
