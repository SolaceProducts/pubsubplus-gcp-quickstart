# Install a Solace PubSub+ Software Message Broker onto Google Compute Engine Linux Virtual Machines

This repository explains how to install a Solace PubSub+ Software Message Broker in various configurations onto Google Compute Engine (GCE) Linux Virtual Machines. This guide is intended mainly for development and demo purposes.

# Description of the Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. Moreover, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

Solace PubSub+ software message brokers can be deployed in either a 3-node High-Availability (HA) cluster, or as a single node deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA cluster is required.

# How to deploy a message broker

In this quick start we go through the steps to set up a message broker either as a single stand-alone instance, or in a 3-node HA cluster.

This is a 3 step process:

## Step 1 (Optional): Obtain a reference to the Docker image of the Solace PubSub+ message broker to be deployed

First, decide which [Solace PubSub+ message broker](https://docs.solace.com/Solace-SW-Broker-Set-Up/Setting-Up-SW-Brokers.htm ) and version is suitable to your use case.

Note: You can skip this step if using the default settings. By default this project installs the Solace PubSub+ software message router, Standard Edition from the latest Docker image available from Docker Hub.

The Docker image reference can be:

*	A public or accessible private Docker registry repository name with an optional tag. This is the recommended option if using PubSub+ Standard. The default is to use the latest message broker image [available from Docker Hub](https://hub.docker.com/r/solace/solace-pubsub-standard/ ) as `solace/solace-pubsub-standard:latest`, or use a specific version [tag](https://hub.docker.com/r/solace/solace-pubsub-standard/tags/ ).

*	A Docker image download URL
     * If using Solace PubSub+ Enterprise Evaluation Edition, go to the Solace Downloads page. For the image reference, copy and use the download URL in the Solace PubSub+ Enterprise Evaluation Edition Docker Images section.

         | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
         | :---: |
         | 90-day trial version of PubSub+ Enterprise |
         | [Get URL of Evaluation Docker Image](http://dev.solace.com/downloads#eval ) |

     * If you have purchased a Docker image of Solace PubSub+ Enterprise, Solace will give you information for how to download the compressed tar archive package from a secure Solace server. Contact Solace Support at support@solace.com if you require assistance. Then you can host this tar archive together with its MD5 on a file server and use the download URL as the image reference.

## Step 2: Create the required GCE Compute Engine instances

The single stand-alone instance requires 1 Compute Engine instance and the HA deployment requires 3.

Repeat these instructions for all instances required and follow the specific requirements for HA setup as applicable.

* Go to your Google Cloud Platform console and create a Compute Engine instance.  Select standard 2 vCPU machine type, and at least 6 GB of memory, a CentOS 7 OS, and a disk with a
size of at least 30 GB depolyed on Centos7 OS:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_1.png "GCE Image creation 1")

### Step 2a: Single Node deployment

* Expand the the Management tab to expose the Automation Startup script panel

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_2.png "GCE Image creation 2")

Cut and paste the code into the panel, replace the value of the variable `SOLACE_DOCKER_IMAGE_REFERENCE` if required to the reference from Step 1, and replace `<ADMIN_PASSWORD>` with the desired password for the management `admin` user. 

```
#!/bin/bash
##################################
# Update following variables as needed:
SOLACE_DOCKER_IMAGE_REFERENCE="solace/solace-pubsub-standard:latest" # default to pull latest PubSub+ standard from docker hub
ADMIN_PASSWORD=<ADMIN_PASSWORD>
#
if [ ! -d /var/lib/solace ]; then
  mkdir /var/lib/solace
  cd /var/lib/solace
  yum install -y wget
  LOOP_COUNT=0
  while [ $LOOP_COUNT -lt 3 ]; do
    wget https://raw.githubusercontent.com/SolaceProducts/solace-gcp-quickstart/master/scripts/install-solace.sh
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
  /var/lib/solace/install-solace.sh -p $ADMIN_PASSWORD -i SOLACE_DOCKER_IMAGE_REFERENCE
fi
```

Now hit the "Create" button on the bottom of this page. This will start the process of starting the GCE instance, installing Docker and finally download and install the VMR.  It is possible to access the VM before the entire Solace solution is up.  You can monitor /var/lib/solace/install.log for the following entry: "'date' INFO: Install is complete" to indicate when the install has completed.

### Step 2b: HA cluster deployment

* If you are configuring 3 HA nodes, expand the Networking tab to edit the Network interfaces panel and customise your IP addresses. You need to pick 3 available internal IPs.

> Tip: gather all 3 IP addresses before continuing.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_3.png "GCE Image creation 3")



## Step 3: Set up network security to allow access
Now that the VMR is instantiated, the network security firewall rule needs to be set up to allow access to both the admin application and data traffic.  Under the "Networking -> VPC network -> Firewall rules" tab add a new rule to your project exposing the required ports:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_network.png "GCE Firewall rules")
`tcp:80;tcp:8080;tcp:1883;tcp:8000;tcp:9000;tcp:55003;tcp:55555`

For more information on the ports required for the message router see the [configuration defaults](http://docs.solace.com/Solace-VMR-Set-Up/VMR-Configuration-Defaults.htm)
. For more information on Google Cloud Platform Firewall rules see [Networking and Firewalls](https://cloud.google.com/compute/docs/networks-and-firewalls)

# Gaining admin access to the VMR

For persons used to working with Solace message router console access, this is still available with the google compute engine instance.  Access the web ssh terminal window by clicking the [ssh] button next to your VMR instance,  then launch a SolOS cli session:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_console.png "GCE console with SolOS cli")
`sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A`

For persons who are unfamiliar with the Solace mesage router or would prefer an administration application, the imbedded PubSub+ Manager is available.  For more information on PubSub+ Manager see the [PubSub+ Manager page](https://docs.solace.com/Solace-PubSub-Manager/PubSub-Manager-Overview.htm).  Management IP will be the Public IP associated with youe GCE instance and port will be 8080 by default.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_webui.png " PubSub+ Manager connection to gce")

# Testing data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and and select your preferred programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/solace_tutorial.png "getting started publish/subscribe")

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/SolaceLabs/solace-gcp-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).