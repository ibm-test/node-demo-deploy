#!/bin/bash

#https://gist.github.com/moshest/c6abc2d2af943d2755c5

sudo apt-get update

curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs

mkdir -p ~/node
cd ~/node
npm install

# add node to startup
hasRc=`grep "su -l $USER" /etc/rc.local | cat`
if [ -z "$hasRc" ]; then
    sudo sh -c "echo 'su -l $USER -c \"cd ~/node; ./start.sh\"' >> /etc/rc.local"
fi
