# Browser-based Obsidian using Xpra
Script to automate setting up Obsidian.md on a browser-accessible Xpra server.

## Overview
This bash script automates the steps necessary to setup a **Ubuntu 22.04 (Linux) ARM64-based virtual machine** to run **Obsidian.md** within in a web browser using a light-weight remote desktop server called **Xpra**. Once running, the server-based Obsidian app can be accessed from anywhere using a unique URL and password. The script can be run with minimal Linux or terminal experience using the steps provided below. For purposes of this guide, the VM is running as an Instance on the Oracle Cloud platform that qualifies for their "free tier" (ARM/Ampere architecture with up to 4 CPU cores and 24GB memory at the time of writing).

The guide assumes you have created a new Oracle Cloud instance with a fresh install of Ubuntu 22.04 and have connected to the terminal via SSH or some other method. Instructions to create and connect to the instance can be found here: https://docs.oracle.com/en-us/iaas/Content/Compute/tutorials/first-linux-instance/overview.htm. 

**Warning:** Setting up access to a remote instance of Obsidian and all of your vault data is *inherently* more risky than Obsidian's normal use, where your files are stored and accessed only on your local machine. The security built into this setup is the *bare minimum* to try to ward off unwanted access to your Xpra server and your vault. Use caution with sensitive files. If in doubt, don't follow a guide posted by a stranger on the internet.

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
- `resetpwd` - to change your Xpra password later on.

## What's happening here?

[Obsidian.md](https://obsidian.md) is expressly designed to operate as a locally-installed application, and the devs have repeatedly emphasized that creating a web-based version of Obsidian goes against their [design philosophy](https://obsidian.md/about), which includes providing full end-to-end encryption of sync'd files. 

The only way to access a web-based version of Obsidian is to host it yourself, to somehow run the app locally and stream it through something like a [docker container](https://github.com/sytone/obsidian-remote) or a full remote desktop, like an AWS WorkSpace or Paperspace. The former requires a dedicated machine, and the latter are pretty expensive for this use case.

This solution attempts to split the difference: use a *free* (as of now) virtual machine provided by Oracle Cloud to stream just the Obsidian window--not a full desktop--and not as a container but as an AppImage running on Linux. [Xpra](https://github.com/Xpra-org/xpra/) is a software that allows us do that. 

Here's an overview of what the script does:

1) Updates and upgrades Linux/Ubuntu system packages
2) Installs several dependencies and libraries that are required for functionality, including:
	- **xpra**: The remote display server
	- **xvfb**: Virtual framebuffer required by Xpra
	- **wget**: To download the Obsidian AppImage
	- **zlib1g-dev**: Compression library needed by Obsidian
	- **fuse**: Required to run AppImage files
	- **libasound2**: Provides sound support for applications, required for Obsidian to run
	- **curl**: Used to setup Cloudflare
	- **wmctrl**: To control the Obsidian window once its open
3) Downloads the Linux ARM64 version of Obsidian and creates a start script that Xpra can use to launch Obsidian
4) Creates a start script that will automatically start Xpra on a reboot, keep it running, keeps Obsidian open, and sets up password authentication to access from the browser.
5) Generates a self-signed SSL certificate using OpenSSL for use by Xpra.
6) Downloads Cloudflare and creates a script that will start a [Quick Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/) with a simple command `tunnel` and output the unique URL that is generated. This tunnel provides a basic level of security by hiding the actual IP address and port of the virtual machine behind Cloudflare's protocols. The SSL certificate we created earlier secures traffic between Cloudflare and Xpra.
7) Creates a script to prompt the user for a new password with a simple command `resetpwd`
8) Performs a couple other optimizations: Xpra content type configuration, update buffer sizes

All of this results in a reasonably reliable "website" that you can visit using your browser of choice to view and edit your Obsidian vaults. With the right instance setup on Oracle Cloud, you can keep the VM running 100% of the time for no charge, and you should only need to re-access the terminal for tweaks, system updates and to restart the tunnel or reset your password. 

## More disclaimers

**Who am I?** A nobody who knows nothing. I have no connection to Obsidian other than being a longtime user. I had never accessed a Linux terminal in my life and had never heard of Xpra before a few weeks ago when I started working on this idea, and I used ChatGPT (along with a lot of documentation) to not only figure out everything that would be required for this setup, but also to take all of the steps and convert them into a single script.

All of which is to say that I've tested this a few times, and it works, but hell if I know why, and if for some reason it doesn't work for you, I'm not going to be able to help. But I can point you to my good friend, ChatGPT, for troubleshooting.

Also, the security measures, such as they are, were also ChatGPT's idea. Are they adequate? Probably should ask someone with experience. I really can't emphasize enough that you should not expose to the internet what you don't want the internet to eventually find. A best practice could be to only run the VM when you need remote access to your vault. That would require connecting via SSH to restart the tunnel.

## Usage and quirks

### Remote vault sync

This setup is almost exclusively designed to use [Obsidian Sync](https://obsidian.md/sync), their built-in vault sync service, in order to synchronize files from this VM to any other device you'd access your vault from. I have been a paying customer for almost 3 years and highly recommend it. For that reason, I haven't even explored what another option would be to sync files. I don't know if Google Drive or iCloud have Linux apps. My guess is that [Obsidian Git](https://github.com/Vinzent03/obsidian-git) is probably the most compatible option.

### Xpra fine tuning

I've found that Xpra streaming is fairly decent, often better and certainly no worse than the off-the-shelf virtual desktops I've tried. The most critical performance setting is making Xpra treat Obsidian as a text editor instead of a browser (this is built into the script). Xpra has some kind of encoding optimizations baked in that massively outperform anything you can tweak yourself (without python skills).

That said, there are some extra options to tinker with if you're so inclined. These are summarized here: [xpra/docs/Usage/Encodings.md at master ￂﾷ Xpra-org/xpra ￂﾷ GitHub](https://github.com/Xpra-org/xpra/blob/master/docs/Usage/Encodings.md)

You can see even more options by accessing the help file with the terminal command:

```
xpra --help
```

All of the options get added to the start command--in our case, the `ExecStart` line of the systemd file, which is accessed here:

```
sudo nano /etc/systemd/system/xpra.service
```

These are the options I have played with myself:

```
--min-quality=90
--min-speed=10
--auto-refresh-delay=0.05
--video-scaling=0
```

If you do update this file, make sure to restart the service with this command:

```
sudo systemctl daemon-reload
sudo systemctl enable xpra.service
```

### Obsidian soft locks

Very occasionally if Xpra with Obsidian has been open in my browser and not in use for a time, Obsidian will soft lock--no cursor, no inputs recognized. But the Xpra hover icons are responsive. I haven't figured out why and haven't found anything strange in logs. Disconnecting and reconnecting, refreshing the browser window or if needed re-opening in a new tab resolves the issue. 

### Shift+Tab

Used for outdenting, especially when using outliner-style notes. It doesn't work here. It's a known bug in Xpra (one of several keyboard-related bugs). Best workaround I've found is to hotkey the outdenting command build into the Outliner plugin, but unfortunately to a different key combination. 
