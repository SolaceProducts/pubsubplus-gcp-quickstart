# solace-gcp-quickstart

## Create a base image

```
#!/bin/bash
if [ ! -f /var/lib/vmr-install.sh ]; then
  cd /var/lib
  yum install -y wget
  wget https://raw.githubusercontent.com/KenBarr/solace-gcp-quickstart/master/vmr-install.sh
  chmod +x ./vmr-install.sh
  ./vmr-install.sh -i <link to VMR Docker Image>
fi
```

## Use the custom image
1. Create and instance based off of custom image with 2 CPU and 6GB memory, and 30GB disk space.
2. Set security rules allow desired protocol access