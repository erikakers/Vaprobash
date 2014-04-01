#!/usr/bin/env bash

echo ">>> Installing Nginx"

[[ -z "$1" ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

if [ -z "$2" ]; then
    public_folder="/vagrant"
else
    public_folder="$2"
fi

# Add repo for latest stable nginx
sudo add-apt-repository -y ppa:nginx/stable

# Update Again
sudo apt-get update

# Install the Rest
sudo apt-get install -y nginx

echo ">>> Configuring Nginx"

# Configure Nginx
# Note the .xip.io IP address $1 variable
# is not escaped
cat > /etc/nginx/sites-available/vagrant << EOF
upstream app_yourdomain {
    server 127.0.0.1:3000;
}

# the nginx server instance
server {
    listen 0.0.0.0:80;
    server_name yourdomain.com yourdomain;
    access_log /var/log/nginx/yourdomain.log;

    # pass the request to the node.js server with the correct headers and much more can be added, see nginx config options
    location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_set_header X-NginX-Proxy true;

      proxy_pass http://app_yourdomain/;
      proxy_redirect off;
    }
 }
EOF

# Turn off sendfile to be more compatible with Windows, which can't use NFS
sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf

sudo service nginx restart
