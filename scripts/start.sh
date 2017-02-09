#!/bin/bash

# http://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-deployments.html#troubleshooting-long-running-processes

cd ~/node
node ./bin/www > /dev/null 2> /dev/null < /dev/null & echo $! > /home/ubuntu/node/scripts/node.pid
