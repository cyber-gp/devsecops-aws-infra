#!/bin/bash

# Running packagecloud installation script 
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | sudo bash

# Install Git LFS
sudo yum install git-lfs -y

# initialize Git LFS
git lfs install -y