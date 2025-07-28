#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
PROJECT_NAME="suneung_dday"
PROJECT_DIR=$(pwd)
USER=$(whoami)

echo "--- Starting Deployment for $PROJECT_NAME ---"

# --- 1. System Update and Package Installation ---
echo "--- Updating system packages and installing dependencies ---"
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev python3-venv nginx

# --- 2. Project Setup ---
echo "--- Setting up Python virtual environment and installing requirements ---"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# --- 3. Django Setup ---
echo "--- Applying database migrations and collecting static files ---"
python manage.py migrate
python manage.py collectstatic --noinput

# --- 4. Gunicorn Setup ---
echo "--- Creating Gunicorn systemd service file ---"
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=gunicorn daemon for $PROJECT_NAME
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind unix:$PROJECT_DIR/$PROJECT_NAME.sock $PROJECT_NAME.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# --- 5. Nginx Setup ---
echo "--- Creating Nginx server block ---"
sudo tee /etc/nginx/sites-available/$PROJECT_NAME > /dev/null <<EOF
server {
    listen 80;
    server_name _; # 실제 도메인 또는 IP 주소로 변경하세요

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $PROJECT_DIR;
    }
    
    location /staticfiles/ {
        root $PROJECT_DIR;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$PROJECT_DIR/$PROJECT_NAME.sock;
    }
}
EOF

# Enable the new Nginx server block
sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# --- 6. Start and Enable Services ---
echo "--- Starting and enabling Gunicorn and Nginx services ---"
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "--- Deployment Finished Successfully! ---"
echo "You can now access your site at your server's IP address." 