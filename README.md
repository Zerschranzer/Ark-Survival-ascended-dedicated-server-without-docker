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

- **At least 4 CPU cores** (6-8 recommended for optimal performance)
- **At least 16 GB of RAM** (8GB will result in crash)
- Sufficient disk space for ARK server files and instances
- Sudo rights or root access
    
  - **A Linux system with one of the following package managers:**
    - apt-get (Debian/Ubuntu)
    - zypper (OpenSUSE)
    - dnf (Fedora)
    - pacman (Arch Linux)


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

1. From the main menu, select "Create New Instance."
2. **Ensure that each instance has a unique name.** When naming instances, avoid naming them similarly, such as "instance" and "instance1." This is important because the "Stop instance" function searches for processes containing the instance name in the start parameters. If the names are too similar, stopping one instance might unintentionally stop another. To prevent this, choose distinct names like "instance1" and "instance2." This ensures that each instance will be managed separately, and no instances will be stopped by mistake.
   
   _Note: I am currently looking for a solution to this issue, but it is challenging since Proton treats the instances as multiple child processes._ 

3. Edit the instance configuration file in your default text editor.

## Instance Configuration

Each server instance in this manager is highly customizable, allowing for unique configurations to suit different gameplay needs.

### Instance-Specific Files

1. **`instance_config.ini`**: The main configuration file for each instance, containing the following settings:
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
   - CustomStartParameters

2. **`GameUserSettings.ini`**: Located in the instance's directory within the `instances` folder. This file allows you to configure game-specific settings for each instance separately.

3. **`Game.ini`** (Optional): You can add this file to the instance directory (`instances/<yourinstance>/Config/`) for additional game settings. If present, it will be applied when starting the instance.

### Important Note on `CustomStartParameters`

If you are upgrading from an older version of the script, please note that the `CustomStartParameters` option was not included in the previous `instance_config.ini` files. As a result, the new script will not automatically add or recognize this field in existing instance configurations. 

To take advantage of this feature, you will need to manually add the following line to each `instance_config.ini` file where you want custom start parameters:

```ini
CustomStartParameters=-NoBattlEye -crossplay -NoHangDetection
```

This is the default setting used by the previous script. You can customize these parameters to suit your server's needs. If you do not add this line, the server will run without additional custom parameters, which might lead to unintended behavior.

**Steps to update your existing instances:**
1. Open the `instance_config.ini` file for each instance:
   ```bash
   nano /path/to/instances/<instance_name>/instance_config.ini
   ```
2. Add the following line under `[ServerSettings]`:
   ```ini
   CustomStartParameters=-NoBattlEye -crossplay -NoHangDetection
   ```
3. Save the file and restart the instance for the changes to take effect.

**Why is this important?**
Custom start parameters allow for greater flexibility in server behavior, such as enabling crossplay or disabling BattlEye. If omitted, your server might not operate as intended, especially if you rely on features enabled by these parameters.

### Configuration Application

- The script creates symlinks to ensure that the correct configuration files are loaded for each instance.
- There's a 30-second delay before starting each instance. This delay allows time for the proper application of configurations, especially when switching between different instances.

### Key Points:
- Each instance can have unique settings in `instance_config.ini`, `GameUserSettings.ini`, and optionally `Game.ini`.
- The use of symlinks and the start delay ensure that the correct configurations are always applied to the right instance.
- This setup provides maximum flexibility, allowing you to run multiple server instances with varied configurations on the same machine.

To modify an instance's configuration, edit the respective files in the instance's directory. The changes will be applied the next time you start the instance.

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

- A big thanks to the developers of these tools who make my server manager possible!
