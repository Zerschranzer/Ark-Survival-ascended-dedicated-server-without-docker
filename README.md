# Server Installation and Startup Guide for Ubuntu-Server: A Beginner's Guide for Linux Users

Welcome to this straightforward guide designed to walk you through the process of installing and starting a ARK Survival Ascended Server on Linux. This guide is tailored for beginners, so no extensive prior knowledge is required.

## Additional Notes for Other Distributions
If you're not using Ubuntu, the installation commands may differ. For example, Fedora or CentOS users would typically use `yum` or `dnf` instead of `apt-get`. It's crucial to consult your distribution's documentation for the equivalent packages or commands to ensure a smooth setup process.

## System Preparation

Before we begin, ensure you are logged in as a user with `sudo` rights or as the `root` user. This will allow you to install necessary packages and make configurations.

Execute the following commands to prepare your system:

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install lib32stdc++6
sudo apt-get install wget
```

These commands add support for the 32-bit architecture and install the necessary libraries along with the `wget` tool needed for downloading.

## Creating a New User

For security reasons, it's advisable to create a new user without `sudo` permissions. In this example, we'll create a user named `asaserver`:

```bash
sudo adduser asaserver
```

Once the user is created, switch to this new user account:

```bash
su asaserver
```

## Downloading and Setting Up the Server

As the `asaserver` user, now execute the following command to download the installation script and make it executable:

```bash
wget https://github.com/Zerschranzer/Ark-Survival-ascended-dedicated-server-without-docker/raw/main/setup.sh && chmod +x setup.sh
```

## Running the Installation Script

Initiate the installation script with the command below:

```bash
./setup.sh
```

The installation may take some time. At the end of the process, you will be prompted to set the server name, choose a password, and determine the Admin password (RCON).

## Managing the Server

After installation, you can manage the server with the `start_stop.sh` script. Execute it with the following command:

```bash
./start_stop.sh
```

The script provides you with the following options:

1. Start the server and update it (if necessary)
2. Stop the server
3. Restart the server and update it
4. Log into the RCON console

Congratulations! You have successfully installed and configured your server.

### How to open ports in Linux:

To open these ports on your Linux server, you can use `iptables`, as Sudo user.`iptables` is a firewall tool available by default on many Linux distributions. Here are the basic commands to open the ports:

```bash
sudo iptables -A INPUT -p udp --dport 7777 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 27020 -j ACCEPT

## Automatic Server Restart with `restart_10_cron.sh`

The `restart_10_cron.sh` script allows you to automatically restart your server. Here's what it does:

1. **Warning**: The script sends a message in the server chat to inform all users that the server will restart in **10 minutes**.
2. **Countdown**: During these 10 minutes, the script waits patiently.
3. **Reminder**: After the 10 minutes have passed, it sends another message that the server will restart in **3 minutes**.
4. **Backup**: Before the restart occurs, the script saves the current state of the server.
5. **Shutdown**: Finally, the server is safely shut down.

### Setting up as a Cron Job

A cron job is a scheduled task that runs automatically at specific times. Here's how to set up the script as a daily cron job for **04:00 AM**:

1. Open a terminal.
2. Type `crontab -e` and press Enter. This opens the crontab file for editing.
3. Add the following line (replace `/path/to/script/` with the actual path to your script):

    ```
    0 4 * * * /path/to/script/restart_10_cron.sh
    ```

4. Save the file and close the editor.

Now your server will automatically restart every day at 04:00 AM!
