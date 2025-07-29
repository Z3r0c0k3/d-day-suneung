#!/bin/bash

# ===================================================================================
# Old Service Cleanup Script
# ===================================================================================
# This script removes the systemd services and Nginx configuration files
# that were created with the old name 'suneung_dday'.
# Run this once to clean up the system before running the main deploy.sh script.
# ===================================================================================

set -e

# --- Helper functions for colored output ---
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[SUCCESS]\e[0m $1"; }

# --- Configuration ---
OLD_SERVICE_NAME="suneung_dday"

echo "======================================================"
info "Starting cleanup of old services: $OLD_SERVICE_NAME"
echo "======================================================"

# --- Stop and Disable Old Gunicorn Services ---
info "Checking for and stopping old Gunicorn services..."
if sudo systemctl is-active --quiet "gunicorn_${OLD_SERVICE_NAME}.service"; then
    sudo systemctl stop "gunicorn_${OLD_SERVICE_NAME}.service"
    success "Stopped old Gunicorn service."
else
    info "Old Gunicorn service is not active."
fi

if sudo systemctl is-enabled --quiet "gunicorn_${OLD_SERVICE_NAME}.service"; then
    sudo systemctl disable "gunicorn_${OLD_SERVICE_NAME}.service"
    success "Disabled old Gunicorn service."
else
    info "Old Gunicorn service is not enabled."
fi

# --- Remove Old Systemd Files ---
info "Removing old systemd files..."
if [ -f "/etc/systemd/system/gunicorn_${OLD_SERVICE_NAME}.service" ]; then
    sudo rm "/etc/systemd/system/gunicorn_${OLD_SERVICE_NAME}.service"
    success "Removed old systemd service file."
fi
if [ -f "/etc/systemd/system/gunicorn_${OLD_SERVICE_NAME}.socket" ]; then
    sudo rm "/etc/systemd/system/gunicorn_${OLD_SERVICE_NAME}.socket"
    success "Removed old systemd socket file."
fi

# --- Remove Old Nginx Files ---
info "Removing old Nginx configuration..."
if [ -f "/etc/nginx/sites-enabled/${OLD_SERVICE_NAME}" ]; then
    sudo rm "/etc/nginx/sites-enabled/${OLD_SERVICE_NAME}"
    success "Removed old Nginx enabled site link."
fi
if [ -f "/etc/nginx/sites-available/${OLD_SERVICE_NAME}" ]; then
    sudo rm "/etc/nginx/sites-available/${OLD_SERVICE_NAME}"
    success "Removed old Nginx available site config."
fi

# --- Reload Daemons and Restart Nginx ---
info "Reloading systemd daemon and checking Nginx..."
sudo systemctl daemon-reload
sudo nginx -t # Test nginx config
sudo systemctl restart nginx
success "Nginx restarted."

echo
success "Cleanup script finished. Old services have been removed."
echo 