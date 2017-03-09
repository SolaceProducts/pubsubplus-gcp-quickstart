# Install a Solace Message Router onto a Google Compute Engine Linux Virtual Machine

The Solace Virtual Message Router (VMR) provides enterprise-grade messaging capabilities deployable in any computing environment. The VMR provides the same rich feature set as Solace’s proven hardware appliances, with the same open protocol support, APIs and common management. The VMR can be deployed in the datacenter or natively within all popular private and public clouds. 

# How to Deploy a VRM
This is a 3 step process:

1. Go to the Solace Developer portal and request a Solace Comunity edition VRM. This process will return an email with a Download link.

<a href="http://dev.solace.com/downloads/download_vmr-ce_hyper-v/" target="_blank">
    <img src="https://raw.githubusercontent.com/KenBarr/solace-gcp-quickstart/master/images/register.png"/>
</a>

2. Go to your Google Cloud Platform console and create a Compute Engine instance.  Ensure at least 2 vCPU and 4 GByte of memory and Centos7 OS:

![alt text](https://raw.githubusercontent.com/KenBarr/solace-gcp-quickstart/master/images/gce_launch_1.png "GCE Image creation 1")

3. Expand the the Management tab to expose the Automation Startup script panel
![alt text](https://raw.githubusercontent.com/KenBarr/solace-gcp-quickstart/master/images/gce_launch_2.png "GCE Image creation 2")

Cut and paste the code into the panel, replace -link to VMR Docker Image- with the link you recieved in step one.

```
#!/bin/bash
if [ ! -f /var/lib/vmr-install.sh ]; then
  cd /var/lib
  yum install -y wget
  wget https://raw.githubusercontent.com/KenBarr/solace-gcp-quickstart/master/vmr-install.sh
  chmod +x /var/lib/vmr-install.sh
  /var/lib/vmr-install.sh -i <link to VMR Docker Image>
fi
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](https://github.com/KenBarr/solace-gcp-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).