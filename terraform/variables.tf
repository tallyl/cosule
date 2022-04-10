variable "region" {
  description = "AWS region for VMs"
  default = "us-east-1"
}

variable "pem_key_name" {
  description = "name of ssh key to attach to hosts generated during apply"
  default     = "opsschool_Tally_consul.pem"
}

variable "ami" {
  description = "ami (ubuntu 18) to use - based on region"
  default = {
    #"us-east-1" = "ami-00ddb0e5626798373"
    #"us-east-1" = "ami-0b0ea68c435eb488d"
    "us-east-1" = "ami-04505e74c0741db8d"
    "us-east-2" = "ami-0fb653ca2d3203ac1"
    #"us-east-2" = "ami-0dd9f0e7df0f0a138"
  }
}

variable "vpc_name" {
  default ="tally-AWS-TF-vpc-opschool"
}

variable "deployment_name" {
  default ="ServiceDiscovery"
}

variable "opschool_assignment" {
  default ="Session2"
}

variable "purpose" {
  default ="Opschool"
}

variable "consul_server_num" {
  default ="3"
}

variable "consul_agent_num" {
  default ="1"
}

variable "common_tags" {
    default =  {
    deployment_name   = "var.deployment_name"
    opschool_assignment = "var.opschool_assignment"
    owner             = "Tally L"
    Purpose           = "var.purpose"
    operational-hours = "247"
    owner-email = "tallyl@traiana.com"
    operational_manager_exclude = "operational_manager_exclude"
  }
}


variable "allow_cidrs" {
  description = "SSH cidrs, passed from the environment layer."
  type =  list(string)
  default = ["84.229.153.195/32","5.29.14.249/32"]
}
