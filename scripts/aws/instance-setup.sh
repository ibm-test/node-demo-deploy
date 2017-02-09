#!/bin/bash

################################################
#
#
# For Ubuntu EC2 Code deploy configuration
#
# $INSTANCE_TYPE - Amazon EC2 instancet type (eg. t2.nano)
# $AMI_ID - machine image ID you will use for the instance
# $KEY_NAME - Amazon EC2 instance key pair to enable SSH access
#
################################################

apt-get -y update
apt-get -y install awscli
apt-get -y install ruby
cd /home/ubuntu
aws s3 cp s3://aws-codedeploy-us-west-2/latest/install . --region us-west-2
chmod +x ./install
./install auto

# aws ec2 run-instances \
#   --image-id $AMI_ID \
#   --key-name $KEY_NAME \
#   --user-data file://aws/instance-setup.sh \
#   --count 1 \
#   --instance-type $INSTANCE_TYPE
#
# output will be $INSTANCE_ID. Use the instance ID to call the create-tags

# aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$APPLICATION_NAME


# --ec2-tag-filters $EC2_TAG_FILTERS