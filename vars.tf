variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  default     = "us-east-1"
}

variable "priv_key_path" {
  description = "Private SSH key path used to connect to EC2 instances"
  default     = "~/.ssh/id_rsa"
}

variable "keypair_name" {
  description = "Key-pair Name"
  default     = "multi-tier-key"
}

variable "pub_key_path" {
  description = "Public SSH key path to be uploaded to EC2 instances"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ec2_username" {
  description = "default SSH user for EC2 instances"
  default     = "ubuntu"
}

variable "myip" {
  description = "your current IP address (bastion host)"
  sensitive   = false
}

variable "rmquser" {
  description = "username for RabbitMQ instance"
  sensitive   = false
}

variable "rmqpass" {
  description = "password for RabbitMQ instance"
  sensitive   = true
}

variable "dbuser" {
  description = "database admin username"
  sensitive   = true
}

variable "dbpass" {
  description = "database admin password"
  sensitive   = true
}

variable "dbname" {
  description = "database name to create in RDS"
  sensitive   = false
}

variable "instance_count" {
  description = "number of EC2 instances for your application stack"
  default     = "1"
}

variable "vpc_name" {
  description = "VPC name tag"
  default     = "multi-tier-proj-vpc"
}

variable "zone1" {
  description = "first Availability zone"
  default     = "us-east-1a"
}

variable "zone2" {
  description = "second Availability zone"
  default     = "us-east-1b"
}

variable "zone3" {
  description = "third Availability zone"
  default     = "us-east-1c"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "172.21.0.0/16"
}

variable "pub_sub1_cidr" {
  description = "public subnet 1"
  default     = "172.21.1.0/24"
}

variable "pub_sub2_cidr" {
  description = "public subnet 2"
  default     = "172.21.2.0/24"
}

variable "pub_sub3_cidr" {
  description = "public subnet 3"
  default     = "172.21.3.0/24"
}

variable "priv_sub1_cidr" {
  description = "private subnet 1"
  default     = "172.21.11.0/24"
}

variable "priv_sub2_cidr" {
  description = "private subnet 2"
  default     = "172.21.12.0/24"
}

variable "priv_sub3_cidr" {
  description = "private subnet 3"
  default     = "172.21.13.0/24"
}

variable "proj_name" {
  description = "project identifier used in naming resources"
  default     = "multi-tier-proj"
}