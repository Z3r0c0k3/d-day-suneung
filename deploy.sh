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
read -p "Enter the project name (e.g., suneung_dday): " PROJECT_NAME
read -p "Enable Debug Mode in .env? (true/false): " DEBUG_MODE
read -p "Enter Allowed Hosts for .env (comma-separated, e.g., localhost,127.0.0.1,yourdomain.com): " ALLOWED_HOSTS_INPUT

if [[ -z "$PROJECT_NAME" || -z "$DEBUG_MODE" || -z "$ALLOWED_HOSTS_INPUT" ]]; then
    echo -e "${YELLOW}Error: All inputs are required. Aborting.${NC}"
    exit 1
fi

# --- 2. Create .env File ---
echo -e "${GREEN}--- Generating new SECRET_KEY and creating .env file ---${NC}"
# Install django just to generate a key, if not available system-wide
if ! python3 -c "from django.core.management.utils import get_random_secret_key" &> /dev/null; then
    sudo apt-get install -y python3-django-common
fi
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

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

# --- 5. Django Project Setup ---
echo -e "${GREEN}--- Applying migrations and collecting static files ---${NC}"
python manage.py migrate
python manage.py collectstatic --noinput

# --- 6. Gunicorn Systemd Service ---
echo -e "${GREEN}--- Configuring Gunicorn systemd service ---${NC}"
PROJECT_DIR=$(pwd)
USER=$(whoami)

sudo tee /etc/systemd/system/${PROJECT_NAME}.service > /dev/null <<EOF
[Unit]
Description=gunicorn daemon for ${PROJECT_NAME}
After=network.target

[Service]
User=${USER}
Group=www-data
WorkingDirectory=${PROJECT_DIR}
ExecStart=${PROJECT_DIR}/venv/bin/gunicorn --workers 3 --bind unix:${PROJECT_DIR}/${PROJECT_NAME}.sock ${PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# --- 7. Nginx Configuration ---
echo -e "${GREEN}--- Configuring Nginx server block ---${NC}"
SERVER_NAME=$(echo ${ALLOWED_HOSTS_INPUT} | sed 's/,/ /g')

sudo tee /etc/nginx/sites-available/${PROJECT_NAME} > /dev/null <<EOF
server {
    listen 80;
    server_name ${SERVER_NAME};

    location = /favicon.ico { alias ${PROJECT_DIR}/staticfiles/favicon.ico; }
    location /static/ {
        alias ${PROJECT_DIR}/staticfiles/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:${PROJECT_DIR}/${PROJECT_NAME}.sock;
    }
}
EOF

# Enable the new Nginx server block
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi
sudo ln -sf /etc/nginx/sites-available/${PROJECT_NAME} /etc/nginx/sites-enabled/

# Test Nginx config
sudo nginx -t

# --- 8. Start and Enable Services ---
echo -e "${GREEN}--- Starting and enabling Gunicorn and Nginx services ---${NC}"
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx
sudo systemctl enable nginx

echo
echo -e "${GREEN}--- Deployment Finished Successfully! ---${NC}"
echo -e "Your Django application is now live. Access it via one of your allowed hosts:"
echo -e "${YELLOW}${ALLOWED_HOSTS_INPUT}${NC}" 