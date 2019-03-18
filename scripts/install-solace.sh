#!/bin/bash

SOLACE_DOCKER_IMAGE_REF="solace/solace-pubsub-standard:latest"
USERNAME=admin
PASSWORD=admin
LOG_FILE=install.log
SWAP_FILE=swap
#cloud init vars
#array of all available cloud init variables to attempt to detect and pass to docker image creation
#see https://docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/Cloud-And-Machine-Tasks/Initializing-Config-Keys-With-Cloud-Init.htm
cloud_init_vars=( routername nodetype service_semp_port system_scaling_maxconnectioncount configsync_enable redundancy_activestandbyrole redundancy_enable redundancy_group_password redundancy_matelink_connectvia service_redundancy_firstlistenport )

# check if routernames contain any dashes or underscores and abort execution, if that is the case.
if [[ $routername == *"-"* || $routername == *"_"* || $baseroutername == *"-"* || $baseroutername == *"_"* ]]; then
  echo "Dashes and underscores are not allowed in routername(s), aborting..." | tee -a ${LOG_FILE}
  exit -1
fi

if [ ! -z "${baseroutername}" ]; then
  cloud_init_vars+=( redundancy_group_node_${baseroutername}0_nodetype )
  cloud_init_vars+=( redundancy_group_node_${baseroutername}0_connectvia )
  cloud_init_vars+=( redundancy_group_node_${baseroutername}1_nodetype )
  cloud_init_vars+=( redundancy_group_node_${baseroutername}1_connectvia )
  cloud_init_vars+=( redundancy_group_node_${baseroutername}2_nodetype )
  cloud_init_vars+=( redundancy_group_node_${baseroutername}2_connectvia )
fi


while [[ $# -gt 1 ]]
do
  key="$1"
  case $key in
      -i|--url)
        SOLACE_DOCKER_IMAGE_REF="$2"
        shift # past argument
      ;;
      -l|--logfile)
        LOG_FILE="$2"
        shift # past argument
      ;;
      -p|--password)
        PASSWORD="$2"
        shift # past argument
      ;;
      -u|--username)
        USERNAME="$2"
        shift # past argument
      ;;
      *)
            # unknown option
      ;;
  esac
  shift # past argument or value
done

echo "`date` INFO: Validate we have been passed a Solace Docker Image reference" &>> ${LOG_FILE}
# -----------------------------------------------------
if [ -z "$SOLACE_DOCKER_IMAGE_REF" ]
then
      echo "USAGE: install-solace.sh -i <Solace Docker Image reference>"
      exit 1
else
      echo "`date` INFO: Solace Docker image reference is ${SOLACE_DOCKER_IMAGE_REF}" &>> ${LOG_FILE}
fi


echo "`date` INFO: Get repositories up to date" &>> ${LOG_FILE}
# ---------------------------------------

yum -y update
yum -y install lvm2

echo "`date` INFO:Set up Docker Repository" &>> ${LOG_FILE}
# -----------------------------------
tee /etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
echo "`date` INFO:/etc/yum.repos.d/docker.repo =\n `cat /etc/yum.repos.d/docker.repo`"  &>> ${LOG_FILE}

echo "`date` INFO:Intall Docker" &>> ${LOG_FILE}
# -------------------------
yum -y install docker-engine

echo "`date` INFO:Configure Docker as a service" &>> ${LOG_FILE}
# ----------------------------------------
mkdir /etc/systemd/system/docker.service.d &>> install.log
tee /etc/systemd/system/docker.service.d/docker.conf <<-EOF
[Service]
  ExecStart=
  ExecStart=/usr/bin/dockerd --iptables=false --storage-driver=devicemapper
EOF
echo "`date` INFO:/etc/systemd/system/docker.service.d =\n `cat /etc/systemd/system/docker.service.d`" &>> ${LOG_FILE}

systemctl enable docker
systemctl start docker

## First make sure Docker is actually up
docker_running=""
loop_guard=10
loop_count=0
while [ ${loop_count} != ${loop_guard} ]; do
  docker_running=`service docker status | grep -o running`
  if [ ${docker_running} != "running" ]; then
    ((loop_count++))
    echo "`date` WARN: Tried to launch Solace but Docker in state ${docker_running}" &>> ${LOG_FILE}
    sleep 5
  else
    echo "`date` INFO: Docker in state ${docker_running}" &>> ${LOG_FILE}
    break
  fi
done

echo "`date` INFO: Get the solace image" &>> ${LOG_FILE}
# ------------------------------------------------
# Determine first if SOLACE_DOCKER_IMAGE_REF is a valid docker registry uri
## Remove any existing solace image
if [ "`docker images | grep solace-`" ] ; then
  echo "`date` INFO: Removing existing Solace images from local docker repo" &>> ${LOG_FILE}
  docker rmi -f `docker images | grep solace- | awk '{print $3}'`
fi
## Try to load SOLACE_DOCKER_IMAGE_REF as a docker registry uri
echo "`date` Testing ${SOLACE_DOCKER_IMAGE_REF} for docker registry uri:" &>> ${LOG_FILE}
if [ -z "`docker pull ${SOLACE_DOCKER_IMAGE_REF}`" ] ; then
  # If NOT in this branch then load was successful
  echo "`date` INFO: Found that ${SOLACE_DOCKER_IMAGE_REF} was not a docker registry uri, retrying if it is a download link" &>> ${LOG_FILE}
  if [[ ${SOLACE_DOCKER_IMAGE_REF} == *"solace.com/download"* ]]; then
    REAL_LINK=${SOLACE_DOCKER_IMAGE_REF}
    # the new download url
    wget -O ${solace_directory}/solos.info -nv  ${SOLACE_DOCKER_IMAGE_REF}_MD5
  else
    REAL_LINK=${SOLACE_DOCKER_IMAGE_REF}
    # an already-existing load (plus its md5 file) hosted somewhere else (e.g. in an s3 bucket)
    wget -O ${solace_directory}/solos.info -nv  ${SOLACE_DOCKER_IMAGE_REF}.md5
  fi
  IFS=' ' read -ra SOLOS_INFO <<< `cat ${solace_directory}/solos.info`
  MD5_SUM=${SOLOS_INFO[0]}
  SolOS_LOAD=${SOLOS_INFO[1]}
  if [ -z ${MD5_SUM} ]; then
    echo "`date` ERROR: Missing md5sum for the Solace load - exiting." | tee /dev/stderr &>> ${LOG_FILE}
    exit 1
  fi
  echo "`date` INFO: Reference md5sum is: ${MD5_SUM}" &>> ${LOG_FILE}

  echo "`date` INFO: Now download from URL provided and validate, trying up to 5 times" &>> ${LOG_FILE}
  LOOP_COUNT=0
  while [ $LOOP_COUNT -lt 5 ]; do
    wget -q -O  ${solace_directory}/${SolOS_LOAD} ${REAL_LINK} || echo "There has been an issue with downloading the Solace load"
    ## Check MD5
    LOCAL_OS_INFO=`md5sum ${solace_directory}/${SolOS_LOAD}`
    IFS=' ' read -ra SOLOS_INFO <<< ${LOCAL_OS_INFO}
    LOCAL_MD5_SUM=${SOLOS_INFO[0]}
    if [ -z "${MD5_SUM}" ] || [ "${LOCAL_MD5_SUM}" != "${MD5_SUM}" ]; then
      echo "`date` WARN: Possible corrupt Solace load, md5sum do not match" &>> ${LOG_FILE}
    else
      echo "`date` INFO: Successfully downloaded ${SolOS_LOAD}" &>> ${LOG_FILE}
      break
    fi
    ((LOOP_COUNT++))
  done
  if [ ${LOOP_COUNT} == 3 ]; then
    echo "`date` ERROR: Failed to download the Solace load, exiting" &>> ${LOG_FILE}
    exit 1
  fi
  ## Load the image tarball
  docker load -i ${solace_directory}/${SolOS_LOAD}
fi
## Image details
export SOLACE_IMAGE_ID=`docker images | grep solace | awk '{print $3}'`
if [ -z "${SOLACE_IMAGE_ID}" ] ; then
  echo "`date` ERROR: Could not load a valid Solace docker image - exiting." &>> ${LOG_FILE}
  exit 1
fi
echo "`date` INFO: Successfully loaded ${SOLACE_DOCKER_IMAGE_REF} to local docker repo" &>> ${LOG_FILE}
echo "`date` INFO: Solace message broker image and tag: `docker images | grep solace | awk '{print $1,":",$2}'`" &>> ${LOG_FILE}


echo "`date` INFO:Set up swap" &>> ${LOG_FILE}
# -----------------------------------------
# Decide which scaling tier applies based on system memory
# and set maxconnectioncount, ulimit, devshm and swap accordingly
MEM_SIZE=`cat /proc/meminfo | grep MemTotal | tr -dc '0-9'`
# check physical memory reported in KiB vs. MiB requirements for Solace scaling tier resources
if [ ${MEM_SIZE} -lt 3837952 ]; then
  # 100 if mem<3748 MiB
  maxconnectioncount="100"
  shmsize="1g"
  ulimit_nofile="2448:6592"
  SWAP_SIZE="1024"
elif [ ${MEM_SIZE} -lt 11592704 ]; then
  # 1000 if 3748 MiB<=mem<11,321 MiB
  maxconnectioncount="1000"
  shmsize="2g"
  ulimit_nofile="2448:10192"
  SWAP_SIZE="2048"
elif [ ${MEM_SIZE} -lt 27258880 ]; then
  # 10000 if 11,321 MiB<=mem<26,620 MiB
  maxconnectioncount="10000"
  shmsize="2g"
  ulimit_nofile="2448:42192"
  SWAP_SIZE="2048"
elif [ ${MEM_SIZE} -lt 53272576 ]; then
  # 100000 if 26,620 MiB<=mem<52,024 MiB
  maxconnectioncount="100000"
  shmsize="3380m"
  ulimit_nofile="2448:222192"
  SWAP_SIZE="2048"
else
  # 200000 if 52,024 MiB<=mem
  maxconnectioncount="200000"
  shmsize="3380m"
  ulimit_nofile="2448:422192"
  SWAP_SIZE="2048"
fi
echo "`date` INFO: Based on memory size of ${MEM_SIZE}KiB, determined maxconnectioncount: ${maxconnectioncount}, shmsize: ${shmsize}, ulimit_nofile: ${ulimit_nofile}, SWAP_SIZE: ${SWAP_SIZE}" &>> ${LOG_FILE}

echo "`date` INFO: Creating Swap space" &>> ${LOG_FILE}
mkdir /var/lib/solace
dd if=/dev/zero of=/var/lib/solace/swap count=${SWAP_SIZE} bs=1MiB
mkswap -f /var/lib/solace/swap
chmod 0600 /var/lib/solace/swap
swapon -f /var/lib/solace/swap
grep -q 'solace\/swap' /etc/fstab || sudo sh -c 'echo "/var/lib/solace/swap none swap sw 0 0" >> /etc/fstab'

echo "`date` INFO:Create a Docker instance from Solace Docker image" &>> ${LOG_FILE}
# -------------------------------------------------------------
SOLACE_CLOUD_INIT="--env SERVICE_SSH_PORT=2222"
[ ! -z "${USERNAME}" ] && SOLACE_CLOUD_INIT=${SOLACE_CLOUD_INIT}" --env username_admin_globalaccesslevel=${USERNAME}"
[ ! -z "${PASSWORD}" ] && SOLACE_CLOUD_INIT=${SOLACE_CLOUD_INIT}" --env username_admin_password=${PASSWORD}"
for var_name in "${cloud_init_vars[@]}"; do
  [ ! -z ${!var_name} ] && SOLACE_CLOUD_INIT=${SOLACE_CLOUD_INIT}" --env $var_name=${!var_name}"
done

echo "SOLACE_CLOUD_INIT set to:" | tee -a ${LOG_FILE}
echo ${SOLACE_CLOUD_INIT} | tee -a ${LOG_FILE}

docker create \
   --uts=host \
   --shm-size=${shmsize} \
   --ulimit core=-1 \
   --ulimit memlock=-1 \
   --ulimit nofile=${ulimit_nofile} \
   --cap-add=IPC_LOCK \
   --cap-add=SYS_NICE \
   --net=host \
   --restart=always \
   --env "system_scaling_maxconnectioncount=${maxconnectioncount}" \
   ${SOLACE_CLOUD_INIT} \
   --name=solace ${SOLACE_IMAGE_ID}

docker ps -a

echo "`date` INFO:Construct systemd for Solace PubSub+" &>> ${LOG_FILE}
# --------------------------------------
tee /etc/systemd/system/solace-docker.service <<-EOF
[Unit]
  Description=solace-docker
  Requires=docker.service
  After=docker.service
[Service]
  Restart=always
  ExecStart=/usr/bin/docker start -a solace
  ExecStop=/usr/bin/docker stop solace
[Install]
  WantedBy=default.target
EOF
echo "`date` INFO:/etc/systemd/system/solace-docker.service =/n `cat /etc/systemd/system/solace-docker.service`" &>> ${LOG_FILE}

echo "`date` INFO: Start the Solace Message Router" &>> ${LOG_FILE}
# --------------------------
systemctl daemon-reload
systemctl enable solace-docker
systemctl start solace-docker

echo "`date` INFO: Port forward workaround for health check packets with dest IP of the load balancer to internal IP" &>> ${LOG_FILE}
# --------------------------
export VM_INTERNAL_IP=`ifconfig eth0 | grep "inet " | awk '{print $2}'`
sudo firewall-cmd --add-forward-port=port=5550:proto=tcp:toport=5550:toaddr=$VM_INTERNAL_IP --permanent
sudo firewall-cmd --reload

echo "`date` INFO: Install is complete" &>> ${LOG_FILE}