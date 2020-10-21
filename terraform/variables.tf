
# Provider id based on Mesosphere account information
variable "profile_id" {
    description = ""
    # Default region is 110465657741_Mesosphere-PowerUser
    default     = "110465657741_Mesosphere-PowerUser"
}

# AWS Region id
variable "region_id" {
    description = ""
    # Default region is us-east-1
    default     = "us-east-1"
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

# Cluster id
variable "cluster_id" {
    description = ""
    # Default region is airgap-????
    default     = "airgap"
}

# ec2.tf
variable "image_id" {
    description = "Amazon AWS AMI"
    # Default ami is based on v1.6.0-rc.2
    default     = "ami-0affd4508a5d2481b"
}

# ec2.tf
variable "image_username" {
    description = "Amazon AWS AMI username"
    # Default ami is based on v1.6.0-rc.2
    default     = "centos"
}

# ec2.tf
variable "ec2_instance_type" {
    description = "AWS EC2 Instance type"
    # Default instance type m5.xlarge
    default     = "m5.xlarge"
}

# Ssh keyname
variable "ssh_key_name" {
    description = ""
    # Comment
    default     = "airgap"
}

# Cluster owner
variable "owner" {
    description = "Owner of the cluster"
    # Comment
    default      = "john.miller@d2iq.com"
}

# Cluster expiration
variable "expiration" {
    description = "Expiration time in hours"
    # Comment
    default     = "6h"
}
