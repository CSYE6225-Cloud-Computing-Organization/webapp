#!/bin/bash
set -e
set -x

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Please install Node.js and try again."
    exit 1
else
    echo "Node.js found."
fi

# Check if MySQL is running
if ! systemctl is-active --quiet mysql; then
    echo "MySQL service is not running. Starting MySQL..."
    sudo systemctl start mysql
    sudo systemctl enable mysql
else
    echo "MySQL service is already running."
fi

# Create the systemd service file for the Node.js app
echo "Creating a systemd service file for the Node.js app..."
cat <<EOF | sudo tee /etc/systemd/system/webapp.service > /dev/null
[Unit]
Description=Node.js App
After=network.target mysql.service

[Service]
ExecStart=/usr/bin/node /home/ubuntu/webapp/src/app.js
Restart=on-failure          # Use on-failure to avoid restarting when the app exits successfully
RestartSec=5                # Restart after 5 seconds if it crashes
User=csye6225
Group=csye6225
EnvironmentFile=/home/ubuntu/.env
WorkingDirectory=/home/ubuntu/webapp
StandardOutput=journal
StandardError=journal
SyslogIdentifier=webapp

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new service file
echo "Reloading systemd to recognize the new service file..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling the webapp service to start on boot..."
sudo systemctl enable webapp.service

# Start the service
echo "Starting the webapp service..."
sudo systemctl start webapp.service

# Check the service status
echo "Checking the service status..."
sudo systemctl status webapp.service --no-pager

# Check logs from the last 1 minute to see if there are any immediate issues
echo "Checking logs from the last minute for errors or issues..."
sudo journalctl -u webapp.service --since "1 minute ago" --no-pager

# Optional: Tail the logs for real-time feedback (uncomment if desired)
# echo "Tailing logs..."
# sudo journalctl -u webapp.service -f
