#!/bin/bash

# ===================================================================================
# Django 'd-day-suneung' Auto-Deployment Script for Ubuntu
# ===================================================================================
# This script automates the deployment of the suneung_dday Django project
# using Gunicorn and Nginx. It should be run by a non-root user with sudo privileges.
# Based on a more robust script from the zerocoke-portfolio project.
# ===================================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper functions for colored output ---
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

# --- Configuration ---
# The name of your Django project (the directory with wsgi.py).
DJANGO_PROJECT_NAME="suneung_dday"
# The name for services and configs, derived from the repository directory name.
REPO_NAME=$(basename "$(pwd)")
# The full path to your project directory.
PROJECT_DIR=$(pwd)
# The user that will run the Gunicorn process.
CURRENT_USER=$(whoami)
# Your server's domain or IP address. Use "_" to match any hostname.
DOMAIN_OR_IP="csat.zerocoke.kr"

echo "==============================================="
info "Starting Deployment for $REPO_NAME"
echo "==============================================="
info "Project Directory: $PROJECT_DIR"
info "Running as User:   $CURRENT_USER"
info "Target Domain/IP:  $DOMAIN_OR_IP"
echo "-----------------------------------------------"


# --- 1. System Update and Package Installation ---
info "Updating system packages and installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev python3-venv nginx
success "System packages are up to date."

# --- 2. Project Setup ---
info "Setting up Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    info "Virtual environment created."
fi

info "Activating virtual environment and installing requirements..."
source venv/bin/activate
pip install -r requirements.txt
success "Python environment is ready."

# --- 3. Django Setup ---
info "Applying database migrations and collecting static files..."
python manage.py migrate
python manage.py collectstatic --noinput
success "Django setup complete."

# --- 4. File Permissions Setup ---
info "Setting file permissions..."
# Set group ownership to www-data so Nginx can access the files
sudo chown -R $CURRENT_USER:www-data $PROJECT_DIR
# Give read and execute permissions to the group
sudo chmod -R 775 $PROJECT_DIR
success "File permissions set correctly."

# --- 5. Gunicorn & Environment Setup ---
if [ -f .env ]; then
    info "Using existing .env file provided by the user."
    info "Please ensure it contains SECRET_KEY, DEBUG=False, and ALLOWED_HOSTS."
else
    info "No .env file found. Creating a new one with production settings..."
    SECRET_KEY_VALUE=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    cat > .env <<EOF
SECRET_KEY='$SECRET_KEY_VALUE'
DEBUG=False
ALLOWED_HOSTS=$DOMAIN_OR_IP
EOF
    success ".env file created. Using domain '$DOMAIN_OR_IP' for ALLOWED_HOSTS."
fi

# --- 6. Gunicorn Setup ---
# Use a unique socket and service name to avoid conflicts.
GUNICORN_SOCKET_FILE="/etc/systemd/system/gunicorn_${REPO_NAME}.socket"
GUNICORN_SERVICE_FILE="/etc/systemd/system/gunicorn_${REPO_NAME}.service"

info "Configuring Gunicorn systemd socket at $GUNICORN_SOCKET_FILE..."
sudo bash -c "cat > $GUNICORN_SOCKET_FILE" <<EOF
[Unit]
Description=gunicorn socket for $REPO_NAME

[Socket]
ListenStream=/run/gunicorn_${REPO_NAME}.sock

[Install]
WantedBy=sockets.target
EOF

info "Configuring Gunicorn systemd service at $GUNICORN_SERVICE_FILE..."
sudo bash -c "cat > $GUNICORN_SERVICE_FILE" <<EOF
[Unit]
Description=gunicorn daemon for $REPO_NAME
Requires=gunicorn_${REPO_NAME}.socket
After=network.target

[Service]
User=$CURRENT_USER
Group=www-data
WorkingDirectory=$PROJECT_DIR
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=$PROJECT_DIR/venv/bin/gunicorn \
          --access-logfile - \
          --workers 3 \
          --bind unix:/run/gunicorn_${REPO_NAME}.sock \
          $DJANGO_PROJECT_NAME.wsgi:application

[Install]
WantedBy=multi-user.target
EOF
success "Gunicorn systemd files created."

# --- 7. Nginx Setup ---
NGINX_CONF_FILE="/etc/nginx/sites-available/$REPO_NAME"
info "Creating Nginx server block at $NGINX_CONF_FILE..."
sudo bash -c "cat > $NGINX_CONF_FILE" <<EOF
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
        alias $PROJECT_DIR/staticfiles/favicon.ico;
    }

    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/run/gunicorn_${REPO_NAME}.sock;
    }
}
EOF

info "Enabling the new Nginx configuration..."
sudo ln -sf $NGINX_CONF_FILE /etc/nginx/sites-enabled/
# Remove default Nginx config if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
    info "Removed default Nginx site configuration."
fi

info "Testing Nginx configuration..."
sudo nginx -t
success "Nginx configuration is valid."

# --- 8. Firewall Setup ---
info "Configuring firewall to allow Nginx traffic..."
sudo ufw allow 'Nginx Full'
# You can check the status with 'sudo ufw status'
success "Firewall configured to allow 'Nginx Full'."

# --- 9. Start and Enable Services ---
info "Starting and enabling Gunicorn and Nginx services..."
sudo systemctl daemon-reload
sudo systemctl start gunicorn_${REPO_NAME}.socket
sudo systemctl enable gunicorn_${REPO_NAME}.socket
sudo systemctl restart gunicorn_${REPO_NAME}.service
# Check if gunicorn is active
sudo systemctl status gunicorn_${REPO_NAME}.socket --no-pager
sudo systemctl status gunicorn_${REPO_NAME}.service --no-pager

info "Restarting Nginx..."
sudo systemctl restart nginx

# --- Final Success Message ---
echo
echo "==============================================="
success "Deployment Finished Successfully!"
echo "==============================================="
echo
info "Your Django project is now live."
if [ "$DOMAIN_OR_IP" == "_" ]; then
    info "Access it at your server's IP address."
else
    info "Access it at: http://$DOMAIN_OR_IP"
fi
echo
info "To monitor Gunicorn logs, run: sudo journalctl -u gunicorn_${REPO_NAME}.service"
info "To monitor Nginx logs, run: sudo journalctl -u nginx.service"
echo 