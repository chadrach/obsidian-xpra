# obsidian-xpra
Script to automate setting up Obsidian.md on a browser-accessible Xpra server.

## Overview
This bash script automates the steps necessary to setup **Xpra** to run **Obsidian** in a web browser on an **Ubuntu 22.04 (Linux) ARM64-based virtual machine**. The script can be run with minimal Linux or terminal experience using the steps provided below. For purposes of this guide, the VM is running as an Instance on the Oracle Cloud platform that qualifies for their "free tier" (ARM/Ampere architecture with up to 4 CPU cores and 24GB memory at the time of writing).

The guide assumes you have created a new Oracle Cloud instance with a fresh install of Ubuntu 22.04 and have connected to the terminal via SSH or some other method. Instructions to create and connect to the instance can be found here: https://docs.oracle.com/en-us/iaas/Content/Compute/tutorials/first-linux-instance/overview.htm. 

## Loading and running the script

Follow these steps after you are connected to the virtual machine via a terminal (e.g., Windows PowerShell):

1. **Create a New Script File:**  
    Once connected to the VM via the terminal, create a new file called `setup.sh` using nano:

    ```bash
    nano setup.sh
    ```
    This command will create the file and open up a text editor called nano within the terminal window.

2. **Paste the Script:**  
    Copy the entire script from the setup.sh file within this repository and paste it into the nano editor. (Tip: In Windows PowerShell, a right-click will paste.)
    
3. **Save and Exit the Editor:**  
    In nano, press `Ctrl+X`, then press `Y` to confirm saving, and finally press `Enter` to write the file.
    
4. **Make the Script Executable:**  
    Run the following command to give the script execute permissions:

    ```bash
    chmod +x setup.sh
    ```
    
5. **Run the Script:**  
    Execute the script by running:
    
    ```
    ./setup.sh
    ```

    The script will prompt you for your desired Xpra password. Follow the on-screen prompts. Whenever a screen pops up with a message, click `Enter` to continue.

6. **Reboot system and initiate Cloudflare tunnel**

    The script will install the necessary packages, set up Xpra and Obsidian, and prompt you to reboot.

    Once rebooted, use the `tunnel` command to start a Cloudflare Tunnel. When the tunnel is established, the terminal will display a unique URL to access Xpra and Obsidian.

7. **Access Xpra and start using Obsidian**

    Navigate to the URL provided when you performed the `tunnel` command. If you want to skip an automatic redirect, go ahead and add `/connect.html` to the end of the URL so you get taken to the login screen.

    Type your password into the password box. You don't need a username or to change any other options (unless you'd like to tinker). Click "Connect".

    The Xpra desktop will load with an Obsidian window visable. When you create a new vault, you'll be shown a Ubuntu-style file explorer to select a folder. I recommend clicking on "Home" and saving all vaults in that folder. Setting up persistent block storage will be the subject of a subsequent guide.
    
### Using Helper Commands: 
After script completes, you can manage your tunnel and update your password using these terminal commands:
    
- `tunnel` - to restart the Cloudflare Quick Tunnel and display the new URL. This will be necessary any time the system reboots.
- `xpra-pass` - to change your Xpra password later on.

