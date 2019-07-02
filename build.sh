#!/bin/bash

TIME=`date +%Y%m%d_%H%M%S`

docker pull debian:sid-slim

docker build $1 $2 $3 $4 -t debian-mysql-server-5.7 .

echo -e "\nHint: Ignore cache with --no-cache"
