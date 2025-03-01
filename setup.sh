#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
# Consolidated setup for Xpra + Obsidian using Cloudflare Quick Tunnel.
# This script installs required packages, configures Xpra (with password protection),
# downloads and sets up Obsidian, updates UDP buffer sizes, and creates helper commands.
# It creates two helper commands:
#   - "tunnel": to restart the Cloudflared Quick Tunnel and display its unique URL.
#   - "xpra-pass": to update the Xpra password.
#
# Note: The Xpra service is configured to use the password file at /home/ubuntu/.xpra/xpra_passwd.txt.

# Prompt for the desired Xpra password if not provided via XPRA_PASSWORD env variable.
if [ -z "$XPRA_PASSWORD" ]; then
  read -sp "Enter desired Xpra password: " XPRA_PASSWORD
  echo
fi

# Update and upgrade system packages.
sudo apt update && sudo apt upgrade -y

# Install required dependencies.
sudo apt install -y xpra xvfb wget zlib1g-dev fuse libasound2 curl netfilter-persistent wmctrl

# Download the Obsidian AppImage (ARM64 version 1.8.7).
wget -O /home/ubuntu/Obsidian.AppImage https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.7/Obsidian-1.8.7-arm64.AppImage
chmod +x /home/ubuntu/Obsidian.AppImage

# Modify Xpra's content type configuration to force text rendering.
sudo bash -c 'echo "role:browser=text" > /usr/share/xpra/content-type/90_fallback.conf'

# Create a startup script for Obsidian.
cat << 'EOF' > /home/ubuntu/start-obsidian.sh
#!/bin/bash
export DISPLAY=:100

# Check if an Obsidian window is already present.
if wmctrl -l | grep -qi "Obsidian"; then
  echo "Obsidian window already exists. Not launching a new instance."
else
  echo "Starting Obsidian..."
  /home/ubuntu/Obsidian.AppImage --disable-gpu --enable-unsafe-swiftshader --disable-software-rasterizer &>> /home/ubuntu/start_obsidian.log &
  sleep 5         # Wait for Obsidian to start and create its window
fi

echo "Maximizing Obsidian window..."
wmctrl -r "Obsidian" -b add,maximized_vert,maximized_horz
EOF
chmod +x /home/ubuntu/start-obsidian.sh

# Set up the Xpra systemd service using the updated password file location.
sudo bash -c 'cat << "EOL" > /etc/systemd/system/xpra.service
[Unit]
Description=Xpra Session
After=network.target

[Service]
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/xpra start :100 --bind-ssl=127.0.0.1:8080 --html=on --start="/home/ubuntu/start-obsidian.sh" --start-on-last-client-exit="/home/ubuntu/start-obsidian.sh" --ssl-auth=file:filename=/home/ubuntu/.xpra/xpra_passwd.txt  --ssl-cert=/etc/xpra/ssl/xpra.crt --ssl-key=/etc/xpra/ssl/xpra.key
ExecStartPost=/bin/bash -c '"'"'while true; do if ! pgrep -x "xpra" > /dev/null; then sudo systemctl restart xpra.service; fi; sleep 5; done &'"'"'
WorkingDirectory=/home/ubuntu
User=ubuntu
Environment=DISPLAY=:100
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL'

# Define certificate directory and file names
CERT_DIR="/etc/xpra/ssl"
CRT_FILE="${CERT_DIR}/xpra.crt"
KEY_FILE="${CERT_DIR}/xpra.key"

# Create the certificate directory 
if [ ! -d "$CERT_DIR" ]; then
  sudo mkdir -p "$CERT_DIR"
  sudo chmod 700 "$CERT_DIR"
fi

# Generate a self-signed certificate with a non-interactive subject.
# The subject omits the email address field.
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CRT_FILE" \
  -subj "/C=US/ST=California/L=SanFrancisco/O=ExampleOrg/OU=IT/CN=localhost"

# Create the Xpra password file at the proper location.
mkdir -p /home/ubuntu/.xpra
echo -n "$XPRA_PASSWORD" > /home/ubuntu/.xpra/xpra_passwd.txt

# Reload and enable the Xpra service.
sudo systemctl daemon-reload
sudo systemctl enable xpra.service
sudo systemctl start xpra.service

# Allow the Xpra service to restart without a sudo password.
echo "ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart xpra.service" | sudo tee /etc/sudoers.d/xpra

# Install Cloudflared for tunneling.
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install -y cloudflared

# Update UDP buffer sizes for improved performance.
sudo sysctl -w net.core.rmem_max=7500000
sudo sysctl -w net.core.wmem_max=7500000

# Persist UDP buffer size changes across reboots.
if ! grep -q "net.core.rmem_max=7500000" /etc/sysctl.conf; then
  echo "net.core.rmem_max=7500000" | sudo tee -a /etc/sysctl.conf
fi
if ! grep -q "net.core.wmem_max=7500000" /etc/sysctl.conf; then
  echo "net.core.wmem_max=7500000" | sudo tee -a /etc/sysctl.conf
fi
sudo sysctl -p

# Create the helper command "tunnel" for restarting the Cloudflared Quick Tunnel.
sudo bash -c 'cat << "EOF" > /usr/local/bin/tunnel
#!/bin/bash
echo "Restarting Cloudflared Quick Tunnel..."
# Kill any existing cloudflared tunnel processes.
pkill -f "cloudflared tunnel --url" 2>/dev/null
# Remove the previous log file.
rm -f /home/ubuntu/cloudflared_quick.log
# Start a new quick tunnel.
nohup cloudflared tunnel --url https://localhost:8080 --no-tls-verify > /home/ubuntu/cloudflared_quick.log 2>&1 &
# Wait for the tunnel to establish.
sleep 10
echo "Cloudflared Quick Tunnel connection details (unique URL):"
tail -n 20 /home/ubuntu/cloudflared_quick.log
EOF'
sudo chmod +x /usr/local/bin/tunnel

# Create the helper command "xpra-pass" to update the Xpra password.
sudo bash -c 'cat << "EOF" > /usr/local/bin/xpra-pass
#!/bin/bash
echo "Enter new Xpra password:"
read -sp "New password: " newpass
echo
mkdir -p /home/ubuntu/.xpra
echo -n "$newpass" > /home/ubuntu/.xpra/xpra_passwd.txt
sudo systemctl restart xpra.service
echo "Xpra password updated successfully."
EOF'
sudo chmod +x /usr/local/bin/xpra-pass

echo -e "\033[1;32mSetup complete\033[0m"
echo -e "\033[1;33mIt is recommended that you reboot your system using: sudo reboot\033[0m"
echo -e "\033[1;33mAfter reboot, and for any subsequent reboot, run 'tunnel' to restart the Cloudflared Quick Tunnel and obtain your new unique URL.\033[0m"
echo -e "\033[1;33mIf you need to change your password, use the command 'xpra-pass' and enter the new password when prompted.\033[0m"
echo -e "\033[1;33mIf you need to reopen your Obsidian window, disconnect and reconnect to the Xpra server or refresh your browser window.\033[0m"
