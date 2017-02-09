#!/bin/bash

if [ -f /home/ubuntu/node/scripts/node.pid ]; then 
  kill `cat /home/ubuntu/node/scripts/node.pid`
  echo 'process killed'
fi
echo "done"
