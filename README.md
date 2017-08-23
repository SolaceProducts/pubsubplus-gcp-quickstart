# Install a Solace Message Router onto a Google Compute Engine Linux Virtual Machine

The Solace Virtual Message Router (VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The VMR provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds.

# How to Deploy a VMR
This is a 3 step process:

* Go to the Solace Developer portal and request a Solace Community edition VMR. This process will return an email with a Download link. Do a right click "Copy Hyperlink" on the "Download the VMR Community Edition for Docker" hyperlink.  This will be needed in the following section.

<a href="http://dev.solace.com/downloads/download_vmr-ce-docker" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/register.png"/>
</a>

* Go to your Google Cloud Platform console and create a Compute Engine instance.  Ensure at least 2 vCPU and 4 GB of memory, a CentOS 7 OS, and a disk with a
size of at least 30 GB depolyed on Centos7 OS:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_1.png "GCE Image creation 1")

* Expand the the Management tab to expose the Automation Startup script panel

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_2.png "GCE Image creation 2")

Cut and paste the code into the panel, replace -link to VMR Docker Image- with the URL you received in step one.

```
#!/bin/bash
###(optional) to set any config keys edit and uncomment the appropriate section
### for the vmr role you are about to configure
##These are example values for configuring a monitoring node
#export baseroutername=gcevmr
#export nodetype=monitoring
#export routername=gcevmr0
#export redundancy_enable=yes
#export redundancy_group_password=gruyerecheese
#export redundancy_group_node_gcevmr0_connectvia=10.154.0.210
#export redundancy_group_node_gcevmr0_nodetype=monitoring
#export redundancy_group_node_gcevmr1_connectvia=10.154.0.211
#export redundancy_group_node_gcevmr1_nodetype=message_routing
#export redundancy_group_node_gcevmr2_connectvia=10.154.0.212
#export redundancy_group_node_gcevmr2_nodetype=message_routing
##These are example values for configuring a primary node
#export baseroutername=gcevmr
#export nodetype=message_routing
#export routername=gcevmr1
#export configsync_enable=yes
#export redundancy_activestandbyrole=primary
#export redundancy_enable=yes
#export redundancy_group_password=gruyerecheese
#export redundancy_group_node_gcevmr0_connectvia=10.154.0.1
#export redundancy_group_node_gcevmr0_nodetype=monitoring
#export redundancy_group_node_gcevmr1_connectvia=10.154.0.2
#export redundancy_group_node_gcevmr1_nodetype=message_routing
#export redundancy_group_node_gcevmr2_connectvia=10.154.0.3
#export redundancy_group_node_gcevmr2_nodetype=message_routing
#export redundancy_matelink_connectvia=10.154.0.3
##These are example values for configuring a backup node
#export baseroutername=gcevmr
#export nodetype=message_routing
#export routername=gcevmr2
#export configsync_enable=yes
#export redundancy_activestandbyrole=backup
#export redundancy_enable=yes
#export redundancy_group_password=gruyerecheese
#export redundancy_group_node_gcevmr0_connectvia=10.154.0.1
#export redundancy_group_node_gcevmr0_nodetype=monitoring
#export redundancy_group_node_gcevmr1_connectvia=10.154.0.2
#export redundancy_group_node_gcevmr1_nodetype=message_routing
#export redundancy_group_node_gcevmr2_connectvia=10.154.0.3
#export redundancy_group_node_gcevmr2_nodetype=message_routing
#export redundancy_matelink_connectvia=10.154.0.2
###
if [ ! -f /var/lib/solace ]; then
  mkdir /var/lib/solace
  cd /var/lib/solace
  yum install -y wget
  LOOP_COUNT=0
  while [ $LOOP_COUNT -lt 3 ]; do
    wget https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/vmr-install.sh
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
  chmod +x /var/lib/solace/vmr-install.sh
  /var/lib/solace/vmr-install.sh -i <link to VMR Docker Image> -p <SolOS/SolAdmin password>
fi
```
* If you are configuring 3 HA nodes, expand the the Network tab to edit the Network interface panel and customise your IP addresses. You need to pick 3 available IPs (same as you configure in your start-up script)

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_3.png "GCE Image creation 3")


Now hit the "Create" button on the bottom of this page or add some VMR config keys before you do.

# Initializing config keys with Cloud-Init
You can use VMR configuration keys to initialise your VMR. All keys introduced with v8.4 are supported except for service_semp_port, username&lowbar;&lt;name&gt;&lowbar;... and interface&lowbar;&lt;ip&lowbar;intf&gt;&lowbar;. . .
see [Initializing-Config-Keys-With-Cloud-Init]( http://docs.solace.com/Solace-VMR-Set-Up/Initializing-Config-Keys-With-Cloud-Init.htm) for a full list.  
To initialise your VMR with HA group configuration, set the additional variable baseroutername to the base name of your choosing for all 3 VMRs and follow the following naming convention for your VMRs (and config keys).
- monitor node = ${baseroutername}0
- primary node = ${baseroutername}1
- backup node  = ${baseroutername}2
 
[All router names need to be based on the baseroutername followed by an index of 0, 1 or 2 as suffix]  
Please note that dashes or underscores are not allowed in your baseroutername or routername and the script will fail to find your config-keys, if you attempt to use them in your names!


# Set up network security to allow access
Now that the VMR is instantiated, the network security firewall rule needs to be set up to allow access to both the admin application and data traffic.  Under the "Networking -> VPC network -> Firewall rules" tab add a new rule to your project exposing the required ports:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_network.png "GCE Firewall rules")
`tcp:80;tcp:8080;tcp:1883;tcp:8000;tcp:9000;tcp:55003;tcp:55555`

For more information on the ports required for the message router see the [configuration defaults](http://docs.solace.com/Solace-VMR-Set-Up/VMR-Configuration-Defaults.htm)
. For more information on Google Cloud Platform Firewall rules see [Networking and Firewalls](https://cloud.google.com/compute/docs/networks-and-firewalls)

# Gaining admin access to the VMR

For persons used to working with Solace message router console access, this is still available with the google compute engine instance.  Access the web ssh terminal window by clicking the [ssh] button next to your VMR instance,  then launch a SolOS cli session:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_console.png "GCE console with SolOS cli")
`sudo docker exec -it solace /usr/sw/loads/currentload/bin/cli -A`

For persons who are unfamiliar with the Solace mesage router or would prefer an administration application the SolAdmin management application is available.  For more information on SolAdmin see the [SolAdmin page](http://dev.solace.com/tech/soladmin/).  To get SolAdmin, visit the Solace [download page](http://dev.solace.com/downloads/) and select OS version desired.  Management IP will be the Public IP associated with youe GCE instance and port will be 8080 by default.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_soladmin.png "soladmin connection to gce")

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
