#!/bin/bash

mkdir /opt/crudapi

sudo aws s3 cp s3://s3-app-symbiosis/crud-api.zip /opt/crudapi.zip
sudo unzip /opt/crudapi.zip -d /opt/crudapi && sudo chmod +x /opt/crudapi/crud-api/app && sudo sh -c "/opt/crudapi/crud-api/app"