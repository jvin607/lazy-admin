#!/usr/bin/env bash

##########################################################
#   Script: createCT.sh
#   Author: JV
#   Date: 20230612
#
#   Summary: Automate creating a Debian 11 based LXC to be
#   used as a docker host because VMs are too resource
#   heavy, and clicking through the "Create CT" menu takes
#   too much time.  I'm lazy ¯\_(ツ)_/¯
#
###########################################################

## Loading secrets file
source ../secrets/secrets.sh

## Defining variables for container (change these for your specific use)

CTID=200						# ID of the container
CTNAME="sandbox-debian11"				# Name of the container
RAM=2048						# Amount of RAM in MB
SWAP=1024						# Swap Partition
SIZE=8							# Disk size in GB
CORES=2							# Number of cores
TEMPLATE="debian-11-standard_11.7-1_amd64.tar.zst"	# Template name
IP="192.168.1.$CTID"					# IP Address for machine
GW="192.168.1.1"					# DFGW
BRIDGE="vmbr0"						# Network interface to be used

## Check local storage for template presence; download if missing
echo "Checking for '$TEMPLATE' in local storage..."

if [ "$(pveam list local | grep -q "$TEMPLATE"; echo $?)" -ne 0 ]; then
	echo "Template '$TEMPLATE' not found.  Downloading..."
	pveam download local $TEMPLATE 
fi

## Stopping and killing old container if running 
if [ "$(pct list | grep $CTID > /dev/null 2>&1; echo $?)" -eq 0 ]; then 
	echo "Stopping old container"
	pct stop $CTID

	echo "Waiting 2 sec for container to die"
	sleep 2

	echo "Deleting old container"
	pct destroy $CTID
       	
fi

echo "Building new container"
pct create $CTID /var/lib/vz/template/cache/$TEMPLATE \
	--unprivileged 1 \
	--hostname $CTNAME \
	--memory $RAM \
	--swap $SWAP \
	--storage local-lvm \
	--rootfs local-lvm:$SIZE \
	--cores $CORES \
	--net0 name=eth0,bridge=$BRIDGE,firewall=1,gw=$GW,ip=$IP/24,type=veth \
	--features keyctl=1,nesting=1,fuse=1 \
	--password="$ROOT_PASS" \
	--start 1 \
	--onboot 0

## All done, showing status of container
clear && echo "Done!"
pct list
sleep 1

## Copying over the kickstart.sh and secrets.sh files from pve to CT
echo "Moving necessary startup files to $CTNAME"
pct push $CTID /root/scripts/sandbox/kickstart.sh /root/kickstart.sh
pct push $CTID /root/scripts/secrets/secrets.sh /root/secrets.sh

## Making the copied files executable
pct exec $CTID chmod +x /root/{secrets.sh,kickstart.sh}

## Running kickstart.sh on CT 
clear
echo "Running kickstart script on $CTNAME..."
sleep 2
pct exec $CTID /root/kickstart.sh


