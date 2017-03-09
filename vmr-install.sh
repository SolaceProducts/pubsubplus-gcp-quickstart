#!/bin/bash

while [[ $# -gt 1 ]]
do
key="$1"
IMAGE=
USERNAME=admin
PASSWORD=admin

case $key in
    -u|--username)
      USERNAME="$2"
      shift # past argument
    ;;
    -p|--password)
      PASSWORD="$2"
      shift # past argument
    ;;
    -i|--image)
      IMAGE="$2"
      shift # past argument
    ;;
    *)
          # unknown option
    ;;
esac
shift # past argument or value
done

echo "`date` Validate we have been passed a VMR image"
# -----------------------------------------------------
if [ -z "$IMAGE" ]
then
      echo "USAGE: vmr-install.sh --image <Solace Docker Image>"
      echo 1
else
      echo "`date` VMR Image is ${IMAGE}"
fi


echo "`date` Get repositories up to date"
# ---------------------------------------

yum -y update
yum -y install lvm2

echo "`date` Set up Docker Repository"
# -----------------------------------
tee /etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

echo "`date` Intall Docker"
# -------------------------
yum -y install docker-engine

echo "`date` Configure Docker as a service"
# ----------------------------------------
mkdir /etc/systemd/system/docker.service.d
tee /etc/systemd/system/docker.service.d/docker.conf <<-EOF 
[Service] 
  ExecStart= 
  ExecStart=/usr/bin/dockerd --iptables=false --storage-driver=devicemapper 
EOF

systemctl enable docker 
systemctl start docker

echo "`date` Pre-Define Solace required infrastructure"
# -----------------------------------------------------
docker volume create --name=jail 
docker volume create --name=var 
docker volume create --name=internalSpool 
docker volume create --name=adbBackup 
docker volume create --name=softAdb

echo "`date` Load the Solace Docker image"
# ----------------------------------------
docker load -i ${IMAGE}

echo "`date` Create a Docker instance from Solace Docker image"
# -------------------------------------------------------------
VMR_VERSION=`docker images | egrep -o [0-9\.]*vmr_docker[\-\.0-9a-z]*`

docker create \
 --privileged=true \
 --shm-size 2g \
 --net=host \
 -v jail:/usr/sw/jail \
 -v var:/usr/sw/var \
 -v internalSpool:/usr/sw/internalSpool \
 -v adbBackup:/usr/sw/adb \
 -v softAdb:/usr/sw/internalSpool/softAdb \
 --env 'username_admin_globalaccesslevel=${USERNAME}' \
 --env 'username_admin_password=${PASSWORD}' \
 --name=solace solace-app:${VMR_VERSION}

echo "`date` Construct systemd for VMR"
# --------------------------------------
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

echo "`date` Start the VMR"
# --------------------------
systemctl daemon-reload
systemctl enable solace-docker-vmr
systemctl start solace-docker-vmr
