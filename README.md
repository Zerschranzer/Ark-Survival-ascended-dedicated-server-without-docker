# ARK: Survival Ascended Linux Server Manager

Welcome to the comprehensive guide for installing and managing ARK: Survival Ascended servers on Linux. This tool, `ark_instance_manager.sh`, allows you to download, install, and manage ARK servers on Linux—despite the lack of a native ARK: Survival Ascended server for Linux. I developed this script to avoid using Docker while offering a flexible and user-friendly solution.

## System Preparation

Ensure you are logged in as a user with `sudo` rights or as the `root` user to add support for 32-bit architectures on x86_64 systems and install the necessary libraries.

### Install Dependencies

Depending on your package manager, use the following commands to install the required libraries:

#### Fedora (dnf):
```bash
sudo dnf install glibc-devel.i686 ncurses-devel.i686 libstdc++-devel.i686
```

#### Ubuntu/Debian (apt):
```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install libc6:i386 libstdc++6:i386 libncursesw6:i386
```

### OpenSUSE (zypper)
```bash
sudo zypper install libX11-6-32bit libX11-devel-32bit gcc-32bit libexpat1-32bit libXext6-32bit
```

#### Arch Linux (pacman):
```bash
sudo pacman -S lib32-libx11 gcc-multilib lib32-expat lib32-libxext
```

### Optional: Create a Separate User for the Server

For security reasons, it's recommended to create a separate user without `sudo` permissions to run the ARK server. Use the following commands to create a new user, depending on your distribution:

```bash
sudo useradd -m -s /bin/bash asaserver
sudo passwd asaserver
```

Switch to this user:

```bash
su - asaserver
```

## Download and Setup the Scripts

To download the `ark_instance_manager.sh` script and make it executable, run the following commands:

```bash
mkdir -p asaserver
cd asaserver
wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/ark_instance_manager.sh
chmod +x ark_instance_manager.sh
```

Additionally, you can download the `ark_restart_manager.sh` script for automated server restart management:

```bash
wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/ark_restart_manager.sh
chmod +x ark_restart_manager.sh
```

## Important Note on Server Installation Location

The server will be installed in the directory where you run the scripts. Ensure you have enough disk space in that location before proceeding with the installation.

## Multi-Instance Management with `ark_instance_manager.sh`

This script allows you to fully manage multiple ARK server instances through an interactive menu.

```bash
./ark_instance_manager.sh
```

Main options in the menu:

1) Install/Update Base Server
2) List Instances
3) Create New Instance
4) Manage Instance
5) Start All Instances
6) Stop All Instances
7) Show Running Instances
8) Delete Instance
9) Exit

### Interactive Menu

The script provides an intuitive, interactive menu for managing server instances. Users can start, stop, configure, and send RCON commands to their servers without needing to manually edit configuration files.

### Argument-Based Usage

The script also supports argument-based usage, making it easy to integrate into Cronjobs or other automated processes. Here are some examples:

- **Update the base server:**
  ```bash
  ./ark_instance_manager.sh update
  ```

- **Start a specific instance:**
  ```bash
  ./ark_instance_manager.sh <instance_name> start
  ```

- **Stop a specific instance:**
  ```bash
  ./ark_instance_manager.sh <instance_name> stop
  ```

- **Send an RCON command to an instance:**
  ```bash
  ./ark_instance_manager.sh <instance_name> send_rcon "<rcon_command>"
  ```

## Automated Server Restarts with `ark_restart_manager.sh`

To automate server restarts and updates, you can use the `ark_restart_manager.sh` script. This script allows you to schedule announcements, save the game world, and restart all instances at a specified time. You can easily modify the script using a text editor like nano: `nano ark_restart_manager.sh`. The script contains comments that describe exactly which values can be changed in the script and what function they serve, for example to adjust the waiting time for restart announcements, etc.

Here’s how to set it up:

1. Download and make the script executable:
   ```bash
   wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/ark_restart_manager.sh
   chmod +x ark_restart_manager.sh
   ```

2. Create a Cronjob to run the restart manager automatically. For example, you can schedule daily restarts at 4:00 AM using the following Cronjob setup:

   Open the crontab file with:
   ```bash
   crontab -e
   ```

   Add the following entry (adjust the path to your script as necessary):

   ```
   0 4 * * * /path/to/ark_restart_manager.sh
   ```

This will automatically restart all server instances and save the world at 4:00 AM every day. The `ark_restart_manager.sh` script will also send in-game messages to warn players before the restart, save the game world, and then restart the servers.

### Customizing Start Parameters

For `ark_instance_manager.sh`, each instance has its own configuration file located in its instance directory. You can edit these configurations through the script's "Edit Configuration" option when managing an instance. Each instance also has its own GameUserSettings.ini located in its instance/config directory, and the script supports cluster management as well.


## Why This Script?

There is no native ARK: Survival Ascended server for Linux, and Docker can be cumbersome and resource-heavy. This script was developed to run the server directly on Linux using Proton, without relying on Docker. It simplifies server management and provides a flexible, automated solution for managing multiple instances.
