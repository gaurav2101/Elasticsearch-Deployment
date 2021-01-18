# Single Node Elasticsearch-Deployment

This Deployment creates a single node elasticsearch cluster with TLS encryption and secure communication enabled. To generate the default passwords for the native elastic stack user one needs to run the elasticsearch utility present in the /usr/share/elasticsearch/bin directory.
Command to generate passwords - ./elasticsearch-setup-passwords auto|interactive
- Auto mode will generate random passwords for the users
- Interactive mode will let user set custom passwords
Node will be accessible through AWS Systems Manager. There is no need to create a bastion/Jump host to login into the server. 

Project Directory Structure

Single-Node ES Cluster
       |
       |__Packer
       |     |
       |     |__files
       |     |     |__elasticsearch.repo
       |     |__scripts     
       |     |     |__elasticsetup.sh
       |     |     |__javasetup.sh
       |     |__amazonlinux2_ami.json
       |
       |__Terraform
             |
             |__main.tf
             |__provider.tf
             |__variables.tf
             |__terraform.tfvars

Tools Used
1. Packer - To create the pre-baked AMI containing elasticsearch installation and configs.
Image Used - Amazon Linux2
AWS Region - us-east-1
Jdk - Amazon Correto 11
Elasticsearch Version - 7.10
 
 Command to generate AMI - packer build amazonlinux2_ami.json

2. Terraform - To provision the system in AWS.

   Steps to provision the infrastucture on AWS
       1.  Go to terraform directory
       2.  Initialize the terraform working directory
               terraform init 
       3.  Create a terraform execution plan
               terraform plan -out tfplan
       4.  Apply the changes to create the desired state 
               terraform apply tfplan
    
