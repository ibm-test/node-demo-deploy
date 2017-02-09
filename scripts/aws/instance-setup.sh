#!/bin/bash

apt-get -y update
apt-get -y install awscli
apt-get -y install ruby
cd /home/ubuntu
aws s3 cp s3://aws-codedeploy-us-west-2/latest/install . --region us-west-2
chmod +x ./install
./install auto
