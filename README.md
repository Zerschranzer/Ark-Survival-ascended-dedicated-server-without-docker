# ARK: Survival Ascended Linux Server Manager

This repository provides a set of scripts—primarily **`ark_instance_manager.sh`**—for installing and managing **ARK: Survival Ascended** (ASA) servers on Linux. Since there is **no official Linux server** for ASA, these scripts leverage **Proton** (plus other utilities) to run the Windows server executable on Linux. The solution does *not* require Docker and includes features for multi-instance management, backups, automated restarts, and more.

---

## Table of Contents

1. [Key Features](#key-features)  
2. [System Requirements](#system-requirements)  
3. [Installation & Setup](#installation--setup)  
4. [Usage](#usage)  
   - [Interactive Menu](#interactive-menu)  
   - [Command-Line Usage](#command-line-usage)  
5. [Managing Instances](#managing-instances)  
   - [Creating a New Instance](#creating-a-new-instance)  
   - [Configuration Files](#configuration-files)  
   - [Maps and Mods](#maps-and-mods)  
   - [Clustering](#clustering)  
6. [Backups & Restores](#backups--restores)  
7. [Automated Restarts](#automated-restarts)  
8. [RCON Console](#rcon-console)  
9. [Troubleshooting](#troubleshooting)  
10. [Credits](#credits)  
11. [License](#license)

---

## 1. Key Features

- **No Docker Required** – Runs the Windows ASA server on Linux via Proton.  
- **Automatic Dependency Checking** – Installs or warns about missing libraries (e.g., 32-bit libs, Python).  
- **Multi-Instance Management** – Configure and run multiple servers on one machine.  
- **Interactive Menu** – User-friendly text-based UI for setup, instance creation, and day-to-day tasks.  
- **Command-Line Interface** – Ideal for automation (cron jobs, scripts) or remote management.  
- **Support for Mods & Maps** – Specify custom maps and Mod IDs in each instance’s config.  
- **Custom Start Parameters** – Easily enable crossplay or disable BattlEye in `instance_config.ini`.  
- **Cluster Support** – Link multiple servers under one Cluster ID for cross-server transfers.  
- **Backup & Restore** – Archive world folders to `.tar.gz` and restore them when needed.  
- **Automated Restarts** – Optional script announces, updates, and restarts your servers on a schedule.  
- **RCON Integration** – A Python-based RCON client (`rcon.py`) for server commands and chat messages.

---

## 2. System Requirements

- **CPU**: Minimum 4 cores (6–8 recommended).  
- **RAM**: Minimum 16 GB (8 GB often leads to crashes or poor performance).  
- **Storage**: Enough disk space for ARK server files (can be quite large).  
- **Linux Distribution with**:
  - `apt-get`, `zypper`, `dnf`, **or** `pacman` (for dependency installation)  
  - `sudo` or root privileges (to install packages)  
- **Internet Connection**: Required to download SteamCMD, Proton, and server files.

> **Note**: ASA is resource-intensive. Make sure your system can handle the load before running multiple instances.

---

## 3. Installation & Setup

1. **Clone this repository**:
   ```bash
   git clone https://github.com/Zerschranzer/Linux-ASA-Server-Manager.git
   cd Linux-ASA-Server-Manager
   ```

2. **Make scripts executable**:
   ```bash
   chmod +x ark_instance_manager.sh ark_restart_manager.sh rcon.py
   ```

3. **Run `ark_instance_manager.sh` (no arguments)**:
   ```bash
   ./ark_instance_manager.sh
   ```
   - From the **interactive menu**, choose **"Install/Update Base Server"**.  
   - This installs (or updates) ASA server files via SteamCMD.  
   - **Important**: Always do this step before creating any instances to ensure all server binaries and Proton are properly set up.

4. **(Optional) Set up a symlink** to run the script from anywhere:
   ```bash
   ./ark_instance_manager.sh setup
   ```
   - This adds `asa-manager` to `~/.local/bin` (if on your PATH), so you can type `asa-manager` globally.

---

## 4. Usage

### Interactive Menu

Running **`./ark_instance_manager.sh`** with **no arguments** enters a menu-based interface:
```
1) Install/Update Base Server
2) List Instances
3) Create New Instance
4) Manage Instance
...
```
You can select numbered options to install the server, create/edit instances, start/stop servers, manage backups, etc.

### Command-Line Usage

Alternatively, pass arguments directly for quick tasks or automation. Common commands:

```bash
# Installs/updates the base server
./ark_instance_manager.sh update

# Starts all existing instances
./ark_instance_manager.sh start_all

# Stops all running instances
./ark_instance_manager.sh stop_all

# Shows which instances are currently running
./ark_instance_manager.sh show_running

# Deletes an instance (prompts for confirmation)
./ark_instance_manager.sh delete <instance_name>

# Managing a specific instance
./ark_instance_manager.sh <instance_name> start
./ark_instance_manager.sh <instance_name> stop
./ark_instance_manager.sh <instance_name> restart
./ark_instance_manager.sh <instance_name> send_rcon "<RCON command>"
./ark_instance_manager.sh <instance_name> backup <world_folder>
```
Use these for scripts (like cron jobs) or when you already know exactly which action you want.

---

## 5. Managing Instances

Each instance lives in `instances/<instance_name>` with its own config, logs, and save folder, allowing for fully independent servers.

### Creating a New Instance

1. In the **interactive menu**, choose **"Create New Instance"**.  
2. Enter a **unique name** (e.g., `island_server_1`, `gen2_pvp`, etc.).  
   - Avoid overly similar names, like `instance` vs. `instance1`, to prevent confusion when stopping/starting.  
3. The script creates the folder structure and opens the new `instance_config.ini`.

### Configuration Files

1. **`instance_config.ini`**  
   - Main server settings for each instance, including:
     - `ServerName`, `ServerPassword`, `ServerAdminPassword`, `MaxPlayers`  
     - `MapName`, `ModIDs`, `Port`, `QueryPort`, `RCONPort`, `SaveDir`  
     - `ClusterID` (if clustering), `CustomStartParameters` (e.g., `-NoBattlEye -crossplay`)  
2. **`GameUserSettings.ini`** in `instances/<instance_name>/Config/`  
   - ARK’s typical server options (XP rates, taming speed, etc.).  
3. **`Game.ini`** (optional)  
   - For more advanced or custom server configurations (engrams, spawn weights, etc.).

> **Tip**: Stopping the server before editing these files is generally recommended. Changes apply on next start.

### Maps and Mods

- **Map**: Set `MapName` in `instance_config.ini` (e.g., `TheIsland_WP`, `Fjordur_WP`).  
- **Mods**: Add mod IDs as a comma-separated list under `ModIDs=`. The script will load them when you start the server.

### Clustering

1. Assign a **shared `ClusterID`** in each instance’s `instance_config.ini`.  
2. The script automatically creates a cluster directory and links them.  
3. Players can transfer characters/dinos/items across these servers in-game.

---

## 6. Backups & Restores

**Backups** help preserve your world data:

- **Via menu**: **"Backup a World from Instance"**. Choose which instance and world folder.  
- **Via CLI**:
  ```bash
  ./ark_instance_manager.sh <instance_name> backup <world_folder>
  ```
  It creates a `.tar.gz` archive in `backups/`.  
  > **Stop** the server to avoid corrupt backups.

**Restores** are also menu-driven: **"Load Backup to Instance"**. This overwrites the existing world files with those from your chosen archive.

---

## 7. Automated Restarts

**`ark_restart_manager.sh`** handles scheduled restarts. It:

1. **Announces** restarts at intervals (e.g., 30 min, 20 min, 10 min).  
2. **Stops** instances gracefully.  
3. **Updates** the base server.  
4. **Restarts** instances with a delay between each.

### Configuration

Open `ark_restart_manager.sh` in a text editor and modify:

- `instances=("myserver1" "myserver2")`  
- `announcement_times=(1800 1200 600 180 10)`  
- `announcement_messages=( ... )`  
- `start_wait_time=30` (seconds between starts)

### Scheduling

Use **cron** to run `ark_restart_manager.sh` daily at (for example) 4:00 AM:
```bash
crontab -e
# Add:
0 4 * * * /path/to/ark_restart_manager.sh
```
Logs are kept in `ark_restart_manager.log`.

---

## 8. RCON Console

The script **`rcon.py`** provides an RCON client. Use it directly:
```bash
./rcon.py 127.0.0.1:27020 -p "MyRconPassword"
```
- Type commands at the prompt (e.g., `broadcast Hello!`).

Or send a single command:
```bash
./rcon.py 127.0.0.1:27020 -p "MyRconPassword" -c "SaveWorld"
```
**`ark_instance_manager.sh`** also uses it internally to shut down servers gracefully and to open an interactive RCON console from the menu.

---

## 9. Troubleshooting

- **Check Logs**: `instances/<instance_name>/server.log` for server errors.  
- **Dependencies**: If the script complains about missing packages, install them (the script tries to help with instructions).  
- **Ports**: Ensure unique ports for each instance, and open them in your firewall if hosting publicly.  
- **Naming Collisions**: Give instances clearly distinct names to avoid accidentally stopping the wrong process.  
- **Performance**: ASA can be resource-heavy. Monitor CPU/RAM usage.  
- **“Invalid cluster ID or no cluster”**: Ensure `ClusterID` matches across all clustered servers.  

---

## 10. Credits

- [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) for server file updates.  
- [Proton GE Custom](https://github.com/GloriousEggroll/proton-ge-custom) for running Windows apps on Linux.  

---

## 11. License

This project is licensed under the [MIT License](LICENSE). Feel free to modify and share these scripts. If you fix bugs or extend functionality, consider opening a PR so everyone benefits.

---

**Enjoy managing your Ark Survival Ascended servers on Linux!**  
If you encounter issues or have ideas to improve these scripts, please open an issue or pull request on GitHub.
