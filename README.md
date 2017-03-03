# solace-gcp-quickstart

## Create a base image
1. Create a project in your gcp account
   https://console.cloud.google.com/iam-admin/projects
2. Create an Email List  google group in your google groups account
   https://groups.google.com/forum/#!creategroup
3. Add the google group to your gcp project
   https://cloud.google.com/compute/docs/access/add-remove-change-permissions-for-team-members
   Add as "Compute Engine" -> "Compute Image User"
4. Create and instance based off of Centos 7 with 2 CPU and 6GB memory, and 30GB disk space.
5. Cut and past the contents of pre-install into the google web shell.
6. Ensure the instance does not delete disk on delete.
7. Delete the instance.
8. Promote the disk to a custom image.
   https://console.cloud.google.com/compute/imagesAdd?_ga=1.189267755.1234043161.1488336718
   set Name<solace-base-iname> Family<solace> Description<Solace base image> Source<disk> Source Disk<yourdisk>

## Use the custom image
1. Create and instance based off of custom image with 2 CPU and 6GB memory, and 30GB disk space.
2. Set security rules allow desired protocol access