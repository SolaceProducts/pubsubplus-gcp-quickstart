# Install a Solace Message Router onto a Google Compute Engine Linux Virtual Machine

The Solace Virtual Message Router (VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The VMR provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds. 

# How to Deploy a VMR

* [Optional] By default this project installs the Solace PubSub+ software message router, Standard Edition.  If you want to install a different version you will have to provide link to version and accompanying md5sum files with the --url and --md5sum flags for solos-install.  Visit http://dev.solace.com/downloads/ to see options and read release notes to understand differences.

* Go to your Google Cloud Platform console and create a Compute Engine instance.  Select standard 2 vCPU machine type, and at least 6 GB of memory, a CentOS 7 OS, and a disk with a
size of at least 30 GB depolyed on Centos7 OS:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_1.png "GCE Image creation 1")

* Expand the the Management tab to expose the Automation Startup script panel

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_2.png "GCE Image creation 2")

Cut and paste the code into the panel, replace -link to VMR Docker Image- with the URL you received in step one.

```
#!/bin/bash
##################################
# Update following variables as needed
SOLACE_DOCKER_IMAGE_REFERENCE="solace/solace-pubsub-standard:latest"
ADMIN_PASSWORD=<Admin password>
#
if [ ! -d /var/lib/solace ]; then
  mkdir /var/lib/solace
  cd /var/lib/solace
  yum install -y wget
  LOOP_COUNT=0
  while [ $LOOP_COUNT -lt 3 ]; do
    wget https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/solos-install.sh
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
  chmod +x /var/lib/solace/solos-install.sh
  /var/lib/solace/solos-install.sh -p $ADMIN_PASSWORD -i SOLACE_DOCKER_IMAGE_REFERENCE
fi
```

Now hit the "Create" button on the bottom of this page. This will start the process of starting the GCE instance, installing Docker and finally download and install the VMR.  It is possible to access the VM before the entire Solace solution is up.  You can monitor /var/lib/solace/install.log for the following entry: "'date' INFO: Install is complete" to indicate when the install has completed.

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