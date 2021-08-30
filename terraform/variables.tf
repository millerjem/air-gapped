
# Profile ID based on AWS account information
variable "profile_id" {
    type = string
}

# AWS Region
variable "region_id" {
    type = string
}

# DKP archive
variable "dkp_archive" {}

# Cluster UUID
resource "random_string" "random" {
    length  = 4
    special = false
    lower   = true
    upper   = false
}

# Cluster ID
variable "cluster_id" {
    default     = "airgap"
}

# ec2.tf
variable "image_id" {
    description = "Amazon AWS AMI"
    # Default ami is based on v1.8.2
    # default     = "ami-00e87074e52e6c9f9"
    default     = "ami-00e87074e52e6c9f9"
}

# ec2.tf
variable "image_username" {
    description = "Amazon AWS AMI username"
    # Default ami is based on v1.8.2
    default     = "centos"
}

# ec2.tf
variable "ec2_instance_type" {
    description = "AWS EC2 Instance type"
    # Default instance type m5.xlarge
    default     = "m5.xlarge"
}

# SSH keyname
variable "ssh_key_name" {
    default     = "airgap"
}

# Cluster owner
variable "owner" {
    description = "Owner of the cluster"
    default      = "john.miller@d2iq.com"
}

# Cluster expiration
variable "expiration" {
    description = "Expiration time in hours only required to D2iQ environments"
    default     = "48h"
}
