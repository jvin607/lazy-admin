#!/usr/bin/env bash

##########################################################
#   Script: kickstart.sh
#   Author: JV
#   Date: 20230614
#
#   Summary: Tired of manually typing out which packages 
#   you need every time you install them? 
#   
#   
#
###########################################################

## Checking to see if file exists
if [ ! -e /root/secrets.sh ]; then
	echo "secrets file not foud"
	exit 1
else
	## Loading and then removing secrets files
	source /root/secrets.sh
	rm -f /root/secrets.sh

fi

## Declaring the packages we want to install
PACKAGES=(
	apt-transport-https # Needs to be installed to append req'd Docker dependencies to system
	ca-certificates
	curl # Needs to be installed to add Docker's GPG key
	gnupg
	htop
	most
	shellcheck
	software-properties-common
	sudo
	tldr
	tmux
	vim	
)

## Updating, upgrading and installing basic packages
echo "Updating and installing necessary packages..."
apt-get update
apt-get install -y "${PACKAGES[@]}" 

## Setting most as our default pager because man page highlighting is nice...
echo "export PAGER=/usr/bin/most" >> /root/.bashrc && source /root/.bashrc

## Adding Docker's GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

## Adding stable repo
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

## Updating package cache
apt-get update

## Required Docker Engine packages
DOCKER_PACKAGES=(
	docker-ce
	docker-ce-cli
	containerd.io
	docker-buildx-plugin
	docker-compose-plugin
	)

## Installing Docker Engine
apt-get install -y "${DOCKER_PACKAGES[@]}"

## Checking Docker Version
docker --version

## Verifying the Docker service is active, then using systemctl to enable service at boot
if [ "$(systemctl is-active docker > /dev/null 2>&1; echo $?)" -eq 0 ]; then
	systemctl enable docker
else
	systemctl start docker && systemctl enable docker
fi

## Testing docker
docker run hello-world

## Creating volume for Portainer server
docker volume create portainer_data

## Downloading and installing Portainer Server container
docker run -d -p 8000:8000 \
	-p 9443:9443 \
	--name portainer \
	--restart=always \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v portainer_data:/data portainer/portainer-ce:latest

## Checking to see whether Portainer has started
docker ps
