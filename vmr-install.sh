#!/bin/bash

while [[ $# -gt 1 ]]
do
key="$1"
URL=
USERNAME=admin
PASSWORD=admin
LOG_FILE=install.log
SWAP_FILE=swap
SOLACE_HOME=`pwd`

case $key in
    -u|--username)
      USERNAME="$2"
      shift # past argument
    ;;
    -p|--password)
      PASSWORD="$2"
      shift # past argument
    ;;
    -i|--url)
      URL="$2"
      shift # past argument
    ;;
    *)
          # unknown option
    ;;
esac
shift # past argument or value
done

echo "`date` Validate we have been passed a VMR url" &>> ${LOG_FILE}
# -----------------------------------------------------
if [ -z "$URL" ]
then
      echo "USAGE: vmr-install.sh --url <Solace Docker URL>"
      echo 1
else
      echo "`date` VMR URL is ${URL}"
fi


echo "`date` Get repositories up to date" &>> ${LOG_FILE}
# ---------------------------------------

yum -y update &>> ${LOG_FILE}
yum -y install lvm2 &>> ${LOG_FILE}

echo "`date` Set up Docker Repository" &>> ${LOG_FILE}
# -----------------------------------
tee /etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
echo "/etc/yum.repos.d/docker.repo =\n `cat /etc/yum.repos.d/docker.repo`" 

echo "`date` Intall Docker" &>> ${LOG_FILE}
# -------------------------
yum -y install docker-engine &>> ${LOG_FILE}

echo "`date` Configure Docker as a service" &>> ${LOG_FILE}
# ----------------------------------------
mkdir /etc/systemd/system/docker.service.d &>> install.log
tee /etc/systemd/system/docker.service.d/docker.conf <<-EOF 
[Service] 
  ExecStart= 
  ExecStart=/usr/bin/dockerd --iptables=false --storage-driver=devicemapper 
EOF
echo "/etc/systemd/system/docker.service.d =\n `cat /etc/systemd/system/docker.service.d`" &>> ${LOG_FILE}

systemctl enable docker &>> ${LOG_FILE}
systemctl start docker &>> ${LOG_FILE}

echo "`date` Set up swap for 4GB machines"
# ----------------------------------------
dd if=/dev/zero of=${SOLACE_HOME}/${SWAP_FILE} count=2048 bs=1MiB &>> ${LOG_FILE}
mkswap -f ${SOLACE_HOME}/${SWAP_FILE} &>> ${LOG_FILE}
chmod 0600 ${SOLACE_HOME}/${SWAP_FILE} &>> ${LOG_FILE}
swapon -f ${SOLACE_HOME}/${SWAP_FILE} &>> ${LOG_FILE}
echo "${SOLACE_HOME}/${SWAP_FILE} none swap sw 0 0" >> /etc/fstab

echo "`date` Pre-Define Solace required infrastructure" &>> ${LOG_FILE}
# -----------------------------------------------------
docker volume create --name=jail &>> ${LOG_FILE}
docker volume create --name=var &>> ${LOG_FILE}
docker volume create --name=internalSpool &>> ${LOG_FILE}
docker volume create --name=adbBackup &>> ${LOG_FILE}
docker volume create --name=softAdb &>> ${LOG_FILE}

echo "`date` Get and load the Solace Docker url" &>> ${LOG_FILE}
# ------------------------------------------------
wget -O /tmp/redirect.html -nv -a ${LOG_FILE} ${URL}
REAL_HTML=`egrep -o "https://[a-zA-Z0-9\.\/\_\?\=]*" /tmp/redirect.html`
wget -O /tmp/soltr-docker.tar.gz -nv -a ${LOG_FILE} ${REAL_HTML}
docker load -i /tmp/soltr-docker.tar.gz &>> ${LOG_FILE}
docker images &>> ${LOG_FILE}


echo "`date` Create a Docker instance from Solace Docker image" &>> ${LOG_FILE}
# -------------------------------------------------------------
VMR_VERSION=`docker images | grep solace | awk '{print $2}'`

docker create \
   --uts=host \
   --shm-size 2g \
   --ulimit core=-1 \
   --ulimit memlock=-1 \
   --ulimit nofile=2448:38048 \
   --cap-add=IPC_LOCK \
   --cap-add=SYS_NICE \
   --net=host \
   --restart=always \
   -v jail:/usr/sw/jail \
   -v var:/usr/sw/var \
   -v internalSpool:/usr/sw/internalSpool \
   -v adbBackup:/usr/sw/adb \
   -v softAdb:/usr/sw/internalSpool/softAdb \
   --env "username_admin_globalaccesslevel=admin" \
   --env "username_admin_password=${PASSWORD}" \
   --env "SERVICE_SSH_PORT=2222" \
   --name=solace solace-app:${VMR_VERSION} &>> ${LOG_FILE}

docker ps -a &>> ${LOG_FILE}

echo "`date` Construct systemd for VMR" &>> ${LOG_FILE}
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
echo "/etc/systemd/system/solace-docker-vmr.service =/n `cat /etc/systemd/system/solace-docker-vmr.service`" &>> ${LOG_FILE} 

echo "`date` Start the VMR"
# --------------------------
systemctl daemon-reload &>> ${LOG_FILE}
systemctl enable solace-docker-vmr &>> ${LOG_FILE}
systemctl start solace-docker-vmr &>> ${LOG_FILE}
