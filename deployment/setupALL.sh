#!/usr/bin/env bash
# deployment/setupALL.sh
# Run this once on a fresh server to set up everything

set -e

PROJECT_NAME="asvenrollment"
PROJECT_DIR="/var/www/$PROJECT_NAME"
DB_USER="asvuser"
DB_PASS="password123"
DB_NAME="asvenrollment_db"
DOMAIN="www.asvenrollment.com"
ALIAS_DOMAIN="asvenrollment.com"
EMAIL="youremail@example.com" # For certbot

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y python3-venv python3-pip git nginx redis-server postgresql postgresql-contrib certbot python3-certbot-nginx

# Create PostgreSQL user & database
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres createdb $DB_NAME -O $DB_USER

# Clone the repo into PROJECT_DIR
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR
git clone https://github.com/yourusername/asvenrollment.git .  # CHANGE THIS to your own GitHub URL

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Copy .env.example to .env and edit it
cp .env.example .env
# You can manually edit .env now (if needed)
# nano .env # Optional step if you need to adjust keys

# Run DB migrations or create tables
venv/bin/python run.py

# Set up Gunicorn systemd service
sudo cp deployment/gunicorn.service /etc/systemd/system/gunicorn.service
sudo cp deployment/celery.service /etc/systemd/system/celery.service
sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl enable celery

# Set up Nginx
sudo cp deployment/nginx.conf /etc/nginx/sites-available/$PROJECT_NAME
sudo ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Obtain SSL
sudo certbot --nginx -d $DOMAIN -d $ALIAS_DOMAIN -m $EMAIL --non-interactive --agree-tos
sudo systemctl reload nginx

# Start services
sudo systemctl start gunicorn
sudo systemctl start celery

echo "Setup complete! Access your site at https://$DOMAIN"
