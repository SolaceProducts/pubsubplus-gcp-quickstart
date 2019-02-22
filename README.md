# Install a Solace PubSub+ Software Message Broker onto Google Compute Engine Linux Virtual Machines

This repository explains how to install a Solace PubSub+ Software Message Broker in various configurations onto Google Compute Engine (GCE) Linux Virtual Machines. This guide is intended for development and demo purposes.

# Description of the Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. Moreover, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

Solace PubSub+ software message brokers can be deployed in either a 3-node High-Availability (HA) cluster, or as a single-node deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA cluster is required.

# How to deploy a message broker

In this quick start we go through the steps to set up a message broker either as a single stand-alone instance, or in a 3-node HA cluster.

## Step 1 (Optional): Obtain a reference to the Docker image of the Solace PubSub+ message broker to be deployed

First, decide which [Solace PubSub+ message broker](https://docs.solace.com/Solace-SW-Broker-Set-Up/Setting-Up-SW-Brokers.htm ) and version is suitable to your use case.

**Note:** You can skip the rest of this step if you're using the default settings. By default this project installs the Standard edition of the Solace PubSub+ software message broker from the latest Docker image available from Docker Hub.

The Docker image reference can be:

*	A public or accessible private Docker registry repository name with an optional tag. This is the recommended option if using PubSub+ Standard. The default is to use the latest message broker image [available from Docker Hub](https://hub.docker.com/r/solace/solace-pubsub-standard/ ) as `solace/solace-pubsub-standard:latest`, or use a specific version [tag](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ).

*	A Docker image download URL
     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |

     * If you have purchased a Docker image of Solace PubSub+ Enterprise, Solace will give you information for how to download the compressed tar archive package from a secure Solace server. Contact Solace Support at support@solace.com if you require assistance. You can then host this tar archive together with its MD5 on a file server and use the download URL as the image reference.

## Step 2: Create the required GCE Compute Engine instances

The single stand-alone instance requires 1 Compute Engine instance, and the HA deployment requires 3 instances for the Primary, Backup, and Monitor nodes.

Repeat these instructions for all instances required, and follow the specific requirements for HA setup as applicable.

### Step 2a: Select instance machine type and parameters

* Go to your Google Cloud Platform console > Compute Engine > VM instances screen and create a Compute Engine instance by clicking on "Create instance".

![alt text](/images/gce_createinstance_1.png "GCE Create VM Instance")

Select standard 2 vCPU machine type, and at least 6 GB of memory, a CentOS 7 OS, and a disk with a size of at least 30 GB deployed on Centos7 OS:

**Note:** In an HA deployment it's recommended to choose a different availability zone for each node. Also, the Monitor node requires only 1 vCPU and the standard 10 GB of disk space.

![alt text](/images/gce_launch_1.png "GCE Image creation 1")

### Step 2b: (HA cluster deployment only) Customize your IP addresses

* If you are configuring 3 HA nodes, expand the Networking tab to edit the Network interfaces panel and customize your IP addresses. You need to pick 3 available internal IPs.

> Tip: Gather all 3 IP addresses before continuing by trying availability (there is feedback if the entered address is being used by another resource), and designating each one to one of the Primary, Backup, and Monitor nodes.

Take note of the configured IP addresses: `<PrimaryIP>`, `<BackupIP>` and `<MonitorIP>`, as they will be used in subsequent steps.

![alt text](/images/gce_launch_3.png "GCE Image creation 3")

It is also recommended to assign a [network tag](https://cloud.google.com/vpc/docs/add-remove-network-tags ) to the VM instances, which will make it easier to set up targeted firewall rules - see also [Step 4](#step-4-set-up-network-security-to-allow-access )

![alt text](/images/gce_network_tag.png "Assigning a network tag")

### Step 2c: Add automated startup script

* Expand the Management tab to expose the "Automation" "Startup script" panel

![alt text](/images/gce_launch_2.png "GCE Image creation 2")

Cut and paste the following code according to your deployment configuration into the panel, replace the value of the variable `SOLACE_DOCKER_IMAGE_REFERENCE` if required to the reference from [Step 1](#step-1-optional-obtain-a-reference-to-the-docker-image-of-the-solace-pubsub-message-broker-to-be-deployed ), and replace `ADMIN_PASSWORD` with the desired password for the management `admin` user.

**Note:** For an HA deployment, additional environment variables are required (see the script section "Add here environment variables..." near the beginning), which is discussed below.   

```shell
#!/bin/bash
##################################
# Update following variables as needed:
SOLACE_DOCKER_IMAGE_REFERENCE="solace/solace-pubsub-standard:latest" # Default to pull latest PubSub+ standard from docker hub
ADMIN_PASSWORD="admin-password"                                      # Update to a real password
GITHUB_BRANCH="SolaceProducts/solace-gcp-quickstart/master"
##################################
# Add here environment variables for HA deployment, not required for single-node deployment.
# export ... see next section HA deployment environment variables
##################################
#
if [ ! -d /var/lib/solace ]; then
  mkdir /var/lib/solace
  cd /var/lib/solace
  yum install -y wget
  LOOP_COUNT=0
  while [ $LOOP_COUNT -lt 3 ]; do
    wget https://raw.githubusercontent.com/$GITHUB_BRANCH/scripts/install-solace.sh
    if [ 0 != `echo $?` ]; then 
      ((LOOP_COUNT++))
    else
      break
    fi
  done
  if [ ${LOOP_COUNT} == 3 ]; then
    echo "`date` ERROR: Failed to download initial install script exiting"
    exit 1
  fi
  chmod +x /var/lib/solace/install-solace.sh
  /var/lib/solace/install-solace.sh -p $ADMIN_PASSWORD -i $SOLACE_DOCKER_IMAGE_REFERENCE
fi
```

#### HA deployment environment variables for the startup script

The environment variables are specific to the role of the nodes, i.e. Primary, Backup, and Monitor.

Assuming `<PrimaryIP>`, `<BackupIP>` and `<MonitorIP>` IP addresses for the nodes, depending on the role, here are the environment variables to be added to the beginning of above startup script:

**Note:** Ensure that you replace the `<PrimaryIP>`, `<BackupIP>` and `<MonitorIP>` values according to your settings.

Primary:
```
##These are example values for configuring a primary node
export baseroutername=gcevmr
export nodetype=message_routing
export routername=gcevmr1
export configsync_enable=yes
export redundancy_activestandbyrole=primary
export redundancy_enable=yes
export redundancy_group_password=gruyerecheese
export redundancy_group_node_gcevmr0_connectvia=<MonitorIP>
export redundancy_group_node_gcevmr0_nodetype=monitoring
export redundancy_group_node_gcevmr1_connectvia=<PrimaryIP>
export redundancy_group_node_gcevmr1_nodetype=message_routing
export redundancy_group_node_gcevmr2_connectvia=<BackupIP>
export redundancy_group_node_gcevmr2_nodetype=message_routing
export redundancy_matelink_connectvia=<BackupIP>
```

Backup:
```
##These are example values for configuring a backup node
export baseroutername=gcevmr
export nodetype=message_routing
export routername=gcevmr2
export configsync_enable=yes
export redundancy_activestandbyrole=backup
export redundancy_enable=yes
export redundancy_group_password=gruyerecheese
export redundancy_group_node_gcevmr0_connectvia=<MonitorIP>
export redundancy_group_node_gcevmr0_nodetype=monitoring
export redundancy_group_node_gcevmr1_connectvia=<PrimaryIP>
export redundancy_group_node_gcevmr1_nodetype=message_routing
export redundancy_group_node_gcevmr2_connectvia=<BackupIP>
export redundancy_group_node_gcevmr2_nodetype=message_routing
export redundancy_matelink_connectvia=<PrimaryIP>
```

Monitor:
```
##These are example values for configuring a monitoring node
export baseroutername=gcevmr
export nodetype=monitoring
export routername=gcevmr0
export redundancy_enable=yes
export redundancy_group_password=gruyerecheese
export redundancy_group_node_gcevmr0_connectvia=<MonitorIP>
export redundancy_group_node_gcevmr0_nodetype=monitoring
export redundancy_group_node_gcevmr1_connectvia=<PrimaryIP>
export redundancy_group_node_gcevmr1_nodetype=message_routing
export redundancy_group_node_gcevmr2_connectvia=<BackupIP>
export redundancy_group_node_gcevmr2_nodetype=message_routing
```


### Step 2d: Submit the create request

Now hit the "Create" button at the bottom of this page. This will begin the process of starting the GCE instance, installing Docker, and finally downloading and installing the message broker. 

It's possible to access the VM before the entire Solace solution is up. You can monitor `/var/lib/solace/install.log` for the following entry: `'date' INFO: Install is complete` to indicate when the installation has completed:

* On the Google Cloud Platform console VM instances screen, locate the instance you've just started and wait for its status to become green (running).

* In the Connect column, select a way to SSH into the VM and connect to it.

* Check the logs:

```
[test@gcp-qs-test ~]$ sudo su
[root@gcp-qs-test test]# cd /var/lib/solace/
[root@gcp-qs-test solace]# ls
install.log  install-solace.sh  swap
[root@gcp-qs-test solace]# tail -f install.log 
:
:
Fri Feb 22 19:04:54 UTC 2019 INFO: Start the Solace Message Router
Fri Feb 22 19:04:54 UTC 2019 INFO: Install is complete
```


## Step 3: (HA cluster deployment only) Assert the primary message broker’s configuration

As described in the [Solace documentation for configuring HA Group](https://docs.solace.com/Configuring-and-Managing/Configuring-HA-Groups.htm ) it's required to assert the primary message broker’s configuration after a Solace PubSub+ software message broker HA redundancy group is configured to support Guaranteed messaging. This can be done through Solace CLI commands as in the [documentation](https://docs.solace.com/Configuring-and-Managing/Configuring-HA-Groups.htm#Config-Config-Sync ) or running following commands at the Primary node (replace `<ADMIN_PASSWORD>` according to your settings):

```
# query redundancy status
curl -sS -u admin:<ADMIN_PASSWORD> http://localhost:8080/SEMP -d "<rpc semp-version=\"soltr/8_5VMR\"><show><redundancy></redundancy></show></rpc>"

# wait until redundancy is up then execute the assert command:

curl -sS -u admin:<ADMIN_PASSWORD> http://localhost:8080/SEMP -d "<rpc semp-version='soltr/8_5VMR'><admin><config-sync><assert-master><router/></assert-master></config-sync></admin></rpc>"
```

## Step 4: Set up network security to allow access

Now that the message broker is instantiated, the network security firewall rule needs to be set up to allow access to both the admin application and data traffic.  Under the "Networking -> VPC network -> Firewall rules" tab add a new rule to your project exposing the required ports.

It is recommended to use the network tag assigned at [Step 2b](#step-2b-ha-cluster-deployment-only-customise-your-ip-addresses ) to target your instances vs. targeting "All instances in the network".

![alt text](/images/gce_network.png "GCE Firewall rules")
`80,8080,1883,8000,9000,55003,55443,55555`

For more information on the ports required for the message broker see the [configuration defaults](https://docs.solace.com/Configuring-and-Managing/SW-Broker-Specific-Config/SW-Broker-Configuration-Defaults.htm ). For more information on Google Cloud Platform Firewall rules see [Networking and Firewalls](https://cloud.google.com/compute/docs/networks-and-firewalls ).

**Note:** For troubleshooting, be aware that there may be existing firewall rules with the target "All instances in the network", or otherwise applicable to the VMs you have created, and they will be automatically applied.

It may also be required to allow egress traffic to the Internet for certain use cases. In this case, create an additional rule using similar steps.

# Gaining admin access to the message broker

Refer to the [Management Tools section](https://docs.solace.com/Management-Tools.htm ) of the online documentation to learn more about the available tools. The Solace PubSub+ Manager is the recommended way to administer the message broker for common tasks.

## PubSub+ Manager, SolAdmin and SEMP access

The Management IP will be the External IP associated with your GCE instance, and the port will be 8080 by default.

**Note:** If using the HA deployment, unless specifically required otherwise, use the GCE instance that is in the Active role (this is the Primary node at the initial setup, but can be the Backup node after a failover).

![alt text](/images/gce_public_ip.png "getting started publish/subscribe")

## Solace CLI access

Access the web ssh terminal window by clicking the [ssh] button next to your message broker instance, then launch a Solace CLI session:

```sh
$sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A

Solace PubSub+ Standard Version 8.12.0.1007

The Solace PubSub+ Standard is proprietary software of
Solace Corporation. By accessing the Solace PubSub+ Standard
you are agreeing to the license terms and conditions located at
http://www.solace.com/license-software

Copyright 2004-2018 Solace Corporation. All rights reserved.
To purchase product support, please contact Solace at: 
http://dev.solace.com/contact-us/

Operating Mode: Message Routing Node

solace-gcp-quickstart-master>
```

# Testing data access to the message broker

To test data traffic though the newly created message broker instance, visit the Solace Developer Portal and select your preferred programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started and provide the specific default port to use.

For single-node configuration, the IP to use will be the External IP associated with your GCE instance. For HA deployment the use of [Client Host List](https://docs.solace.com/Features/SW-Broker-Redundancy-and-Fault-Tolerance.htm#Failover ) is required for seamless failover - this will consist of the External IP addresses associated with your Primary and Backup node GCE instances.

![alt text](/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceProducts/solace-gcp-quickstart/graphs/contributors) who participated in this project.


## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
