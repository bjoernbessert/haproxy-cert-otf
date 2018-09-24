#!/bin/bash

docker-compose kill
docker-compose rm -f
docker-compose up -d
docker-compose exec haproxy bash

