#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Fun. Colors! ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Django Production Deployment Script ---${NC}"
echo -e "${YELLOW}This script will configure Nginx and Gunicorn for your Django project.${NC}"
echo

# --- 1. User Input ---
# Use the current directory name as the default service name
DEFAULT_SERVICE_NAME=$(basename "$PWD" | tr -d '[:space:]')
read -p "Enter a name for the Gunicorn service and Nginx config [${DEFAULT_SERVICE_NAME}]: " SERVICE_NAME
SERVICE_NAME=${SERVICE_NAME:-${DEFAULT_SERVICE_NAME}}

read -p "Enter the Django project name (the one with wsgi.py) [suneung_dday]: " DJANGO_PROJECT_NAME
DJANGO_PROJECT_NAME=${DJANGO_PROJECT_NAME:-suneung_dday}

read -p "Enable Debug Mode in .env? (true/false): " DEBUG_MODE
read -p "Enter Allowed Hosts for .env (comma-separated, e.g., localhost,127.0.0.1,yourdomain.com): " ALLOWED_HOSTS_INPUT

if [[ -z "$SERVICE_NAME" || -z "$DJANGO_PROJECT_NAME" || -z "$DEBUG_MODE" || -z "$ALLOWED_HOSTS_INPUT" ]]; then
    echo -e "${YELLOW}Error: All inputs are required. Aborting.${NC}"
    exit 1
fi

# --- 2. Create .env File ---
echo -e "${GREEN}--- Generating new SECRET_KEY and creating .env file ---${NC}"
# Use Python's built-in secrets module for a secure key. This is more robust than relying on a system package.
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')

cat > .env << EOF
# Environment variables for Django project
DEBUG=${DEBUG_MODE}
SECRET_KEY='${SECRET_KEY}'
ALLOWED_HOSTS=${ALLOWED_HOSTS_INPUT}
EOF
echo ".env file created successfully."

# --- 3. System Update and Package Installation ---
echo -e "${GREEN}--- Updating system and installing dependencies (python, nginx) ---${NC}"
sudo apt-get update
sudo apt-get install -y python3-pip python3-dev python3-venv nginx

# --- 4. Project & Python Environment Setup ---
echo -e "${GREEN}--- Setting up Python virtual environment and installing requirements ---${NC}"
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# --- 5. Django Setup ---
echo -e "${GREEN}--- Applying migrations and collecting static files ---${NC}"
python manage.py migrate
python manage.py collectstatic --noinput

# --- 6. Gunicorn Systemd Service ---
echo -e "${GREEN}--- Configuring Gunicorn systemd service ---${NC}"
PROJECT_DIR=$(pwd)
USER=$(whoami)

sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null <<EOF
[Unit]
Description=gunicorn daemon for ${SERVICE_NAME}
After=network.target

[Service]
User=${USER}
Group=www-data
WorkingDirectory=${PROJECT_DIR}
ExecStart=${PROJECT_DIR}/venv/bin/gunicorn --workers 3 --bind unix:${PROJECT_DIR}/${SERVICE_NAME}.sock ${DJANGO_PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# --- 7. Nginx Configuration ---
echo -e "${GREEN}--- Configuring Nginx server block ---${NC}"
SERVER_NAME=$(echo ${ALLOWED_HOSTS_INPUT} | sed 's/,/ /g')

sudo tee /etc/nginx/sites-available/${SERVICE_NAME} > /dev/null <<EOF
server {
    listen 80;
    server_name ${SERVER_NAME};
    set $project_path /d-day-suneung;

    location = /favicon.ico { alias ${PROJECT_DIR}/staticfiles/favicon.ico; }
    location /static/ {
        alias ${PROJECT_DIR}/staticfiles/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:${PROJECT_DIR}/${SERVICE_NAME}.sock;
    }
}
EOF

# Enable the new Nginx server block
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi
sudo ln -sf /etc/nginx/sites-available/${SERVICE_NAME} /etc/nginx/sites-enabled/

# Test Nginx config
sudo nginx -t

# --- 8. Start and Enable Services ---
echo -e "${GREEN}--- Starting and enabling Gunicorn and Nginx services ---${NC}"
sudo systemctl daemon-reload
sudo systemctl restart ${SERVICE_NAME}.service
sudo systemctl enable ${SERVICE_NAME}.service
sudo systemctl restart nginx
sudo systemctl enable nginx

echo
echo -e "${GREEN}--- Deployment Finished Successfully! ---${NC}"
echo -e "Your Django application is now live. Access it via one of your allowed hosts:"
echo -e "${YELLOW}${ALLOWED_HOSTS_INPUT}${NC}" 