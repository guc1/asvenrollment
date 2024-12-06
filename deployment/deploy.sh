#!/usr/bin/env bash
# deployment/deploy.sh
# After pulling code updates, run this to apply changes

set -e
PROJECT_DIR="/var/www/asvenrollment"

cd $PROJECT_DIR
git pull
source venv/bin/activate
pip install -r requirements.txt

# If using migrations:
# venv/bin/flask db upgrade

sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl restart celery
sudo systemctl reload nginx

echo "Deployment complete!"
