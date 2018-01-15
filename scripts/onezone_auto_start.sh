#! /bin/bash

id=`docker ps -a | grep onezone | awk '{print $1}'`
docker start $id
