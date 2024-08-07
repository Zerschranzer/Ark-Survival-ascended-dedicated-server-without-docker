# ARK Survival Ascended Server: Installation, Startup and Manager script for Linux-Server: A Beginner's Guide for Linux Users

Welcome to this straightforward guide designed to walk you through the process of installing and starting an ARK Survival Ascended Server on Linux. This guide is tailored for beginners, so no extensive prior knowledge is required.

## System Preparation

Before we begin, ensure you are logged in as a user with `sudo` rights or as the `root` user. This will allow you to add support for the 32-bit architecture on x86_64 systems and install the necessary libraries.

### If you use Fedora Server or other distributions that use `dnf` as package manager

To install the required dependencies on Fedora, execute the following commands:

```bash
sudo dnf install glibc-devel.i686
sudo dnf install ncurses-devel.i686
sudo dnf install libstdc++-devel.i686
```

### If you use Ubuntu Server or other distributions that use `apt` as package manager

For Ubuntu, you can install the dependencies as follows:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install libc6:i386
sudo apt install libncurses5:i386
sudo apt install libstdc++6:i386
```

### If you use Debian Server

When working with Debian, which also uses `apt`, the steps differ slightly due to the absence of the `sudo` command installed by default.

Switch to the root user:

```bash
su -
```

Enter your root password. Then execute the following commands:

```bash
dpkg --add-architecture i386
apt update
apt install libc6:i386
apt install libncurses5:i386
apt install libstdc++6:i386
```

### If you use OpenSUSE Server or other distributions that use `zypper` as package manager

For openSUSE, you can install the required dependencies with this command:

```bash
sudo zypper install libX11-6-32bit libX11-devel-32bit gcc-32bit libexpat1-32bit libXext6-32bit
```

### If you use Arch Linux or Arch-based distributions

For Arch Linux and its derivatives, you can install the required dependencies with this command:

```bash
sudo pacman -S lib32-libx11 gcc-multilib lib32-expat lib32-libxext
```


## Optional but Recommended: Creating a Separate User

For security reasons, it's recommended to create a separate user without sudo permissions to run the ARK server. This step is optional but highly advised for better system security.

To create a new user (e.g., named 'asaserver'):

```bash
sudo adduser asaserver
sudo passwd asaserver
```

If the `adduser` command doesn't work, try:

```bash
sudo useradd -m -U asaserver
sudo passwd asaserver
```

After creating the user, switch to this new account:

```bash
su - asaserver
```

## Downloading and Setting Up the Server

Execute the following command to download the installation script and make it executable:

```bash
wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/asamanager.sh && chmod +x asamanager.sh
```

## Important Note About Server Installation Location

The server will be installed in the directory from which you run the script. Make sure you have sufficient disk space in this location before running the installation. If you're using a separate user as recommended, this will typically be in that user's home directory.


## Running the Installation Script

Initiate the installation script with the command below:

```bash
./asamanager.sh
```

The script provides you with the following options:

1. Start Server
2. Stop Server
3. Restart and Update Server
4. Open RCON Console (exit with CTRL+C)
5. Change Map
6. Change Mods
7. Check Server Status
8. Download and Setup the Server
9. help

Select option number 8 to `download and set up the server`. Before the setup starts, you get asked if you want to change the map or if you want to use mods. Once the setup is complete, the script will prompt you to choose a name, password, and RCON password for your server. Just follow the instructions.

Congratulations! You have successfully installed and configured your server. To start, stop, restart or enter the Rcon_Console, just run `./asamanager.sh` in the console, and follow the instructions.

## Executing the Script with Arguments

The `asamanager.sh` script can also be executed with additional arguments. Currently supported command-line options include:

**Available command-line options:**
- **start** - Start the ARK server
- **stop** - Stop the ARK server
- **restart** - Restart and update the ARK server
- **console** - Open RCON console
- **status** - Show the ARK server status
- **setup** - Download and set up the server
- **send_rcon** - Send a command to the ARK server via RCON
- **help** - Display this help message

For example, to send a specific RCON command to the server, you can execute it as follows:

```bash
./asamanager.sh send_rcon "your rcon command"
```

### How to open ports in Linux:

To open these ports on your Linux server, you can use `iptables`, as a Sudo or root user.`iptables` is a firewall tool available by default on many Linux distributions. Here are the basic commands to open the ports:

```bash
sudo iptables -A INPUT -p udp --dport 7777 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 27020 -j ACCEPT
```

### Setting Up Automatic Server Restarts with Cron Jobs for Daily Server Software Updates

A cron job is a scheduled task that automatically runs at specific times. Here's how to set up the script as a daily cron job with following functions:

Every day at 3:40 AM, the script sends a message in the server chat that the server will restart in 20 minutes.

Ten minutes later, at 3:50 AM, the script sends another message that the server will restart in 10 minutes.

At 3:57 AM, a message is sent that the server will restart in 3 minutes.

One minute later, at 3:58 AM, the script executes the saveworld command to save the current state of the world.

Finally, at 4:00 AM, the server is restarted.

1. Type `crontab -e` and press Enter. This opens the crontab file for editing. If you get asked, which editor you want to use, I recommend nano.
2. Add the following lines at the end of the file (replace `/path/to/asamanager.sh` with the actual path to your script):

```
40 3 * * * /path/to/asamanager.sh send_rcon "serverchat Server restart in 20 minutes"
50 3 * * * /path/to/asamanager.sh send_rcon "serverchat Server restart in 10 minutes"
57 3 * * * /path/to/asamanager.sh send_rcon "serverchat Server restart in 3 minutes"
58 3 * * * /path/to/asamanager.sh send_rcon "saveworld"
00 4 * * * /path/to/asamanager.sh restart
```

3. Save the file and close the editor.
(With vim texteditor press ESC :wq ENTER to save the file)

## Customizing Start Parameters in `asamanager.sh` Script

If you wish to modify the startup parameters of your ASA Server, you can locate them in the `script_config.cfg` configuration file within the directory where you ran the script. However, if you're looking to add mods or change the map, I recommend using my script, which will automatically adjust the `script_config.cfg` file for you. You should only manually change the startup parameters if you need to alter the port or other settings.
