# Install a Solace Message Router onto a Google Compute Engine Linux Virtual Machine

The Solace Virtual Message Router (VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The VMR provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds. 

# How to Deploy a VMR
This is a 3 step process:

* Go to the Solace Developer portal and request a Solace Comunity edition VMR. This process will return an email with a Download link.

<a href="https://products.solace.com/download/VMR_DOCKER_COMM" target="_blank">
    <img src="https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/register.png"/>
</a>

* Go to your Google Cloud Platform console and create a Compute Engine instance.  Ensure at least 2 vCPU and 4 GByte of memory and Centos7 OS:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_1.png "GCE Image creation 1")

* Expand the the Management tab to expose the Automation Startup script panel

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_launch_2.png "GCE Image creation 2")

Cut and paste the code into the panel, replace -link to VMR Docker Image- with the link you recieved in step one.

```
#!/bin/bash
if [ ! -f /var/lib/solace ]; then
  mkdir /var/lib/solace
  cd /var/lib/solace
  yum install -y wget
  wget https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/vmr-install.sh
  chmod +x /var/lib/solace/vmr-install.sh
  /var/lib/solace/vmr-install.sh -i <link to VMR Docker Image>
fi
```

# Set up network security to allow access
Now that the VMR is instantated, the network security firewall rule needs to be set up to allow access to both the admin application and data traffic.  Under the networking->firewall tab add a new rule to your project exposing the required ports:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_network.png "GCE Firewall rules")

For more information on the ports required for the message router see the [configuration defaults](http://docs.solace.com/Solace-VMR-Set-Up/VMR-Configuration-Defaults.htm)
For more information on Google Cloud Platform Firewall rules see [Networking and Firewalls](https://cloud.google.com/compute/docs/networks-and-firewalls)

# Gaining admin access to the VMR

For persons used to working with Solace message router console access, this is still available with the google compute engine instance.  Access the web ssh terminal window by clicking the [ssh] button next to your VMR instance,  then launch a SolOS cli session:

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_console.png "GCE console with SolOS cli")

For persons who are unfamiliar with the Solace mesage router or would prefer an administration application the SolAdmin managmanent application is available.  For more information on SolAdmin see the [SolAdmin page](http://dev.solace.com/tech/soladmin/).  To get SolAdmin, visit the Solace [download page](http://dev.solace.com/downloads/) and select OS version desired.  Access IP will be the External IP accosiated with youe GCE instance and port will be 8080 by default.

![alt text](https://raw.githubusercontent.com/SolaceLabs/solace-gcp-quickstart/master/images/gce_soladmin.png "soladmin connection to gce")

# Testing data access to the VMR

To test data traffic though the newly created VMR instance, visit the Solace developer portal and and select your prefered programming langauge to [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started.

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