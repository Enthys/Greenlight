#!/bin/bash

TIMEZONE="Europe/Sofia"

USERNAME="greenlight"

read -p "Enter password for greenlight DB user: " DB_PASSWORD

export LC_ALL=en_US.UTF-8

add-apt-repository -y universe

apt update
apt -y -o Dpkg::Options::="--force-confnew" upgrade

timedatectl set-timezone ${TIMEZONE}
apt -y install locales-all

useradd --create-home --shell "/bin/bash" --groups sudo "${USERNAME}"
passwd --delete "${USERNAME}"
chage --lastday 0 "${USERNAME}"

rsync --archive --chown=${USERNAME}:${USERNAME} /root/.ssh /home/${USERNAME}

ufw allow 22
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

apt -y install fail2ban curl

curl -L https://github.com/golang-migrate/migrate/releases/download/v4.14.1/migrate.linux-amd64.tar.gz | tar xvz
mv migrate.linux-amd64 /usr/local/bin/migrate

apt -y install postgresql

sudo -i -u postgres psql -c "CREATE DATABASE greenlight"
sudo -i -u postgres psql -d greenlight -c "CREATE EXTENSION IF NOT EXISTS citext"
sudo -i -u postgres psql -d greenlight -c "CREATE ROLE greenlight WITH LOGIN PASSWORD '${DB_PASSWORD}'"


echo "GREENLIGHT_DB_DSN='postgres://greenlight:${DB_PASSWORD}@localhost:5432/greenlight'" >> /etc/environment

apt -y install -y debian-keyring debian-archive-keyring apt-transport-https
curl -L https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo apt-key add -
curl -L https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee -a /etc/apt/sources.list.d/caddy-stable.list
apt update
apt -y install caddy

echo "Script complete! Rebooting..."
reboot
