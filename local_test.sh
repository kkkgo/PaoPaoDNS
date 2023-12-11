#!/bin/sh
cd prebuild-paopaodns||exit
docker build --no-cache -t sliamb/prebuild-paopaodns . 
cd ..||exit
docker build --no-cache -t sliamb/paopaodns . 
docker rm -f paopaodns
docker run --name paopaodns --rm -d -e USE_MARK_DATA=yes -e ADDINFO=yes sliamb/paopaodns
docker exec -it paopaodns sh