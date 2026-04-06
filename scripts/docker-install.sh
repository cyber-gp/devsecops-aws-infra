#!/bin/bash

# =======================================================================
# Description: This script installs Docker on an Amazon Linux 2 instance.
# =======================================================================

# check the linux distribution and version (2023 or 2)
cat /etc/os-release

# Update the installed packages and package cache on your instance.
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start the Docker service
sudo service docker start

# Add the ec2-user to the docker group so you can execute Docker commands without using sudo.
sudo usermod -a -G docker ec2-user

# log out and log in again to pick up the new docker group permissions
exit
# ssh -i "key-pair.pem" ec2-user@your-ec2-instance-public-ip

# Verify that the ec2-user can run Docker commands without using sudo.
# docker ps