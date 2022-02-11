# terraform_module_for_dynamic-subnet_creation

## About

This is a Terraform Module used for creating Dynamic subnets ( both Public and Private ), the module itself will create and configure vpc, subnets, route table, Network ACLs etc. The module will do the ip-subnet calculations too.

## Input Data Required

-  Number of Public Subnets
-  Number of Private Subnets  ( if the value is 0 the module will not create NAT Gateway, Elastic IP and the routes associated with it )
-  CIDR-Block
-  Project Name

## To use the Module

-  Add below Module block on the main terraform code, replace source with correct value.
   ```sh
    module "vpc" {
      source = "PATH-TO-THE-MODULE/terraform_module_for_dynamic-subnet_creation"
      project = var.project
      Public-Count = var.Public_Count
      Private-Count = var.Private_Count
      cidr = var.cidr_vpc
    }
   ``` 
 -  Include below variables on your variable.tf,
     - project
     - Public-Count
     - Private-Count
     - cidr    
 -  To get the Public Subnet ID's use,
     -  ```sh
         module.vpc.Public-Subnet-IDs
        ```
 -  To get the Private Subnet ID's use,
     -  ```sh
         module.vpc.Private-Subnet-IDs
        ```
 -  To get VPC ID use,
     -  ```sh
         module.vpc.VPC_ID
        ```
 
