# ARK Survival Ascended Server: Installation, Startup and Manager script for Linux-Server: A Beginner's Guide for Linux Users


Welcome to this straightforward guide designed to walk you through the process of installing and starting a ARK Survival Ascended Server on Linux. This guide is tailored for beginners, so no extensive prior knowledge is required.



## System Preparation

Before we begin, ensure you are logged in as a user with `sudo` rights or as the `root` user. This will allow you to add support for the 32-bit architecture and install the necessary libraries.

## If you use Fedora Server or other distributions that use `dnf` as package manager 

To install the required dependencies on Fedora, execute the following commands:

```bash
sudo dnf install glibc-devel.i686
sudo dnf install ncurses-devel.i686
sudo dnf install libstdc++-devel.i686
```

## If you use Ubuntu Server or other distributions that use `apt` as package manager 
For Ubuntu, you can install the dependencies as follows:

```bash
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install libc6:i386
sudo apt install libncurses5:i386
sudo apt install libstdc++6:i386
```

## If you use Debian Server
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

## If you use OpenSUSE Server or other distributions that use `zypper` as package manager 
For openSUSE, you can install the required dependencies with this command:

```bash
sudo zypper install libX11-6-32bit libX11-devel-32bit gcc-32bit libexpat1-32bit libXext6-32bit
```




## Creating a New User

For security reasons, it's advisable to create a new user without `sudo` permissions. In this example, we'll create a user named `asaserver` (as a debian user, dont use `sudo` before those commands) :

```bash
sudo useradd -m asaserver
sudo passwd asaserver
```

Once the user is created, switch to this new user account:

```bash
su asaserver
```

## Downloading and Setting Up the Server

As the `asaserver` user, or whatever username you have chosen, now execute the following command to download the installation script and make it executable:

```bash
cd
wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/asamanager.sh && chmod +x asamanager.sh
```

## Running the Installation Script

Initiate the installation script with the command below:

```bash
./asamanager.sh
```

The script provides you with the following options:

1) Start server
2) Stop server
3) Restart and update server
4) Open RCON console (exit with CTRL+C)
5) Download and Setup the Server

Select option number 5 to `Download and Setup the Server`. Once the setup is complete, the script will prompt you to choose a name, password, and RCON password for your server.

Congratulations! You have successfully installed and configured your server. 
To start, stop, restart or enter the Rcon_Console, just run `./asamanager.sh` in the console, and follow the instructions.

### How to open ports in Linux:

To open these ports on your Linux server, you can use `iptables`, as a Sudo or root user.`iptables` is a firewall tool available by default on many Linux distributions. Here are the basic commands to open the ports:

```bash
sudo iptables -A INPUT -p udp --dport 7777 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 27020 -j ACCEPT
```


### Setting Up Automatic Server Restarts with Cron Jobs for Daily Server Software Updates

A cron job is a scheduled task that automatically runs at specific times. Here’s how to set up the script as a daily cron job with following functions:

Every day at 3:40 AM, the script sends a message in the server chat that the server will restart in 20 minutes.
Ten minutes later, at 3:50 AM, the script sends another message that the server will restart in 10 minutes.
At 3:57 AM, a message is sent that the server will restart in 3 minutes.
One minute later, at 3:58 AM, the script executes the saveworld command to save the current state of the world.
Finally, at 4:00 AM, the server is restarted.

1. switch to the asaserver user or whatever username you have chosen with:
```bash
su asaserver
```
2. Type `crontab -e` and press Enter. This opens the crontab file for editing. If you get asked, wich editior you want to use, i recommend nano
4. Add the following lines at the end of the file (replace `/home/asaserver/asamanager.sh` with the actual path to your script. If you created a user named asaserver, it should be `/home/asaserver/asamanager.sh`):

    ```
    40 3 * * * /home/asaserver/asamanager.sh send_rcon "serverchat Server restart in 20 minutes"
    50 3 * * * /home/asaserver/asamanager.sh send_rcon "serverchat Server restart in 10 minutes"
    57 3 * * * /home/asaserver/asamanager.sh send_rcon "serverchat Server restart in 3 minutes"
    58 3 * * * /home/asaserver/asamanager.sh send_rcon "saveworld"
    00 4 * * * /home/asaserver/asamanager.sh restart
    ```

5. Save the file and close the editor.



## Customizing Start Parameters in `asamanager.sh` Script

The `asamanager.sh` script contains start parameters for the ARK server, which dictate the map being played and how the server is configured. By default, the map is set to "TheIsland". To play on a different map, you need to change the start parameters.

### Example: Switching to the "Scorched Earth" Map

1. Open the `asamanager.sh` script in a text editor like nano.
2. In the beginning, there is a line that starts with `STARTPARAMS=`.
3. Replace `TheIsland_WP` with `ScorchedEarth_WP` to switch the map.

### Example: Switching to the "Svartalfheim" Mod Map

To play on the "Svartalfheim" map, which is a mod map, you need to specify the mod ID. Here's how:

1. Change the map designation to `Svartalfheim_WP`.
2. Add `-mods=893657` at the end of the parameters to load the mod.

The modified line should look like this:

```
STARTPARAMS="Svartalfheim_WP?listen?Port=7777?RCONPort=27020?RCONEnabled=True -WinLiveMaxPlayers=50 -mods=893657"
```

Save the changes and restart the server to load the new map with the desired settings.
