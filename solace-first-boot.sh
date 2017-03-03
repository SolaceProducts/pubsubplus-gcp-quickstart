#!/bin/bash

cd  /tmp
wget https://storage.googleapis.com/solace_vmr/latest
SOLACE_VMR_LATEST = `cat latest`

wget  ${SOLACE_VMR_LATEST}

docker load -i ./soltr*.tar.gz

VMR_VERSION=`docker images | egrep -o [0-9\.]*vmr_docker[\-\.0-9a-z]*`

#Define a create script
tee ./docker-create <<-EOF
#!/bin/bash
docker create \
 --privileged=true \
 --shm-size 2g \
 --net=host \
 -v jail:/usr/sw/jail \
 -v var:/usr/sw/var \
 -v internalSpool:/usr/sw/internalSpool \
 -v adbBackup:/usr/sw/adb \
 -v softAdb:/usr/sw/internalSpool/softAdb \
 --env 'username_admin_globalaccesslevel=admin' \
 --env 'username_admin_password=admin' \
 --name=solace solace-app:${VMR_VERSION}
EOF

#Make the file executable
chmod +x ./docker-create

#Launch the VMR
./docker-create

#Construct systemd for VMR
tee /etc/systemd/system/solace-docker-vmr.service <<-EOF
[Unit]
  Description=solace-docker-vmr
  Requires=docker.service
  After=docker.service
[Service]
  Restart=always
  ExecStart=/usr/bin/docker start -a solace
  ExecStop=/usr/bin/docker stop solace
[Install]
  WantedBy=default.target
EOF

#Start the solace service and enable it at system start up.
systemctl daemon-reload
systemctl enable solace-docker-vmr
systemctl start solace-docker-vmr
systemctl disable solace-first-boot