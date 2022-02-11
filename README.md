# terraform_module_for_dynamic-subnet_creation

## About

This is a Terraform Module used for creating Dynamic subnets ( both Public and Private ), the module itself will create and configure vpc, subnets, route table, Network ACLs etc. The module will do the ip-subnet calculations too.

## Input Data Required

-  Number of Public Subnets
-  Number of Private Subnets  ( if the value is 0 the module will not create NAT Gateway, Elastic IP and the routes associated with it )
-  CIDR-Block
-  Project Name

## To use the Module

-  ```sh
    git clone https://github.com/ManuGeorge96/terraform_VPC_module_for_dynamic-subnet_creation.git
   ``` 
-  Add below Module block on the main terraform code, replace source with correct value.
   ```sh
    module "vpc" {
      source = "PATH-TO-THE-MODULE/terraform_VPC_module_for_dynamic-subnet_creation"
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
     - ```sh
         module.vpc.VPC_ID
        ```
 
 ## Behind The Code
 
 -  SECTION - 1
    -  VPC Creation. 
       ```sh
        resource "aws_vpc" "vpc-requestor" {
        cidr_block = var.cidr
        enable_dns_hostnames = true
        tags = {
          Name = "${var.project}-vpc"
          Project = "${var.project}"
         }
       }
      ```
 -  SECTION - 2
    -  Calculates the new-bit for the CIDR Block.
       ```sh
        locals {
        subnetr = floor(log((var.Public-Count + var.Private-Count) * 2,2))
        }
       ```
    -  Creation of Public Subnets.
       ```sh
        resource "aws_subnet" "requestor-Public" {
           cidr_block = cidrsubnet(var.cidr, local.subnetr, "${count.index}")
           availability_zone = element(data.aws_availability_zones.AZ-requestor.names, count.index)
           vpc_id = aws_vpc.vpc-requestor.id
           map_public_ip_on_launch = true
           count = var.Public-Count
            }
         ``` 
     -  Creation of Private Subnets
        ```sh
          resource "aws_subnet" "requestor-Private" {
          count = var.Private-Count
          cidr_block = cidrsubnet(var.cidr, local.subnetr, "${count.index + var.Public-Count}")
          availability_zone = element(data.aws_availability_zones.AZ-requestor.names, count.index)
          vpc_id = aws_vpc.vpc-requestor.id
          map_public_ip_on_launch = false
           }  
        ```
 - SECTION - 3
     - Creation of Elastic IP, creates only if there is private subnets,
       ```sh
         resource "aws_eip" "requestor-eip" {
           vpc = true
           count = var.Private-Count == "0" ? 0 : 1
         }
        ```
 - SECTION - 4
     - Ctreation of NAT Gateway , creates only if there is private subnets,
       ```sh
        resource "aws_nat_gateway" "requestor-NAT" {
          count = var.Private-Count == "0" ? 0 : 1
          allocation_id = aws_eip.requestor-eip[0].id
          subnet_id = aws_subnet.requestor-Public[0].id
         }
        ```
 - SECTION - 5
     - Creation of Internet Gateway.
       ```sh
         resource "aws_internet_gateway" "requestor-IGw" {
           vpc_id = aws_vpc.vpc-requestor.id
         }
        ```
 - SECTION - 6
     - Public Route Table Creation
       ```sh
         resource "aws_route_table" "requestor-Public-RTB" {
           vpc_id = aws_vpc.vpc-requestor.id
           route {
             cidr_block = "0.0.0.0/0"
             gateway_id = aws_internet_gateway.requestor-IGw.id
           }
          }
         ```
      - Private Route Table Creation, creates only if there is private subnets
        ```sh
          resource "aws_route_table" "requestor-Private-RTB" {
            count = var.Private-Count == "0" ? 0 : 1
            vpc_id = aws_vpc.vpc-requestor.id
            route {
              cidr_block = "0.0.0.0/0"
              nat_gateway_id = aws_nat_gateway.requestor-NAT[0].id
            }
           }
          ```
 -  SECTION - 7
    - Route Table Assosciation for both Public and Private,
      ```sh
        resource "aws_route_table_association" "requestor-public" {
          count = "${length(aws_subnet.requestor-Public.*.cidr_block)}"
          subnet_id = "${element(aws_subnet.requestor-Public.*.id, count.index)}"
          route_table_id = aws_route_table.requestor-Public-RTB.id
        }
        resource "aws_route_table_association" "requestor-private" {
          count = "${length(aws_subnet.requestor-Private.*.cidr_block)}"
          subnet_id = "${element(aws_subnet.requestor-Private.*.id, count.index)}"
          route_table_id = aws_route_table.requestor-Private-RTB[0].id
        }
       ```
- SECTION - 8
   -  Network ACL for both public and private witsh association,
      ```sh
        resource "aws_network_acl" "public" {
           vpc_id     = aws_vpc.vpc-requestor.id
           subnet_ids = aws_subnet.requestor-Public.*.id
           egress {
               rule_no    = 100
               action     = "allow"
               cidr_block = "0.0.0.0/0"
               from_port  = 0
               to_port    = 0
               protocol   = "-1"
            }
          ingress {
               rule_no    = 100
               action     = "allow"
               cidr_block = "0.0.0.0/0"
               from_port  = 0
               to_port    = 0
               protocol   = "-1"
            }
       ```    
